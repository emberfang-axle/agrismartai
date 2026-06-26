"""Optional Supabase persistence for API detections (service role)."""

from __future__ import annotations

import logging
import os
import uuid
from typing import Any, Dict, Optional

import httpx

logger = logging.getLogger(__name__)

_SUPABASE_URL = os.getenv("SUPABASE_URL", "").rstrip("/")
_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")


def is_configured() -> bool:
    return bool(_SUPABASE_URL and _SERVICE_KEY and ".supabase.co" in _SUPABASE_URL)


def _headers(*, prefer: str = "return=representation") -> Dict[str, str]:
    return {
        "apikey": _SERVICE_KEY,
        "Authorization": f"Bearer {_SERVICE_KEY}",
        "Content-Type": "application/json",
        "Prefer": prefer,
    }


async def upload_scan_image(
    image_bytes: bytes,
    user_id: str,
    *,
    content_type: str = "image/jpeg",
) -> Optional[str]:
    """Upload leaf image to public scan-images bucket. Returns public URL."""
    if not is_configured() or not image_bytes:
        return None

    object_path = f"{user_id}/{uuid.uuid4().hex}.jpg"
    upload_url = f"{_SUPABASE_URL}/storage/v1/object/scan-images/{object_path}"
    try:
        async with httpx.AsyncClient(timeout=12.0) as client:
            res = await client.post(
                upload_url,
                headers={
                    "apikey": _SERVICE_KEY,
                    "Authorization": f"Bearer {_SERVICE_KEY}",
                    "Content-Type": content_type,
                    "x-upsert": "true",
                },
                content=image_bytes,
            )
            if res.status_code >= 400:
                logger.warning("Storage upload failed: %s %s", res.status_code, res.text)
                return None
            return f"{_SUPABASE_URL}/storage/v1/object/public/scan-images/{object_path}"
    except Exception as exc:
        logger.warning("Storage upload error: %s", exc)
        return None


async def log_detection(
    *,
    user_id: Optional[str],
    disease_code: str,
    disease_name: str,
    confidence: float,
    model_version: str,
    is_rice_leaf: bool,
    image_url: Optional[str] = None,
    barangay: str = "New Bataan",
    latitude: Optional[float] = None,
    longitude: Optional[float] = None,
    image_bytes: Optional[bytes] = None,
) -> Optional[str]:
    """Insert a scan row (+ activity log). Returns scan id when successful."""
    if not is_configured() or not user_id:
        return None

    if image_url is None and image_bytes:
        image_url = await upload_scan_image(image_bytes, user_id)

    payload: Dict[str, Any] = {
        "user_id": user_id,
        "disease_code": disease_code,
        "disease_name": disease_name,
        "confidence": confidence,
        "model_version": model_version,
        "is_rice_leaf": is_rice_leaf,
        "image_url": image_url,
        "barangay": barangay,
    }
    if latitude is not None:
        payload["latitude"] = latitude
    if longitude is not None:
        payload["longitude"] = longitude

    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            disease_res = await client.get(
                f"{_SUPABASE_URL}/rest/v1/diseases",
                headers=_headers(),
                params={"code": f"eq.{disease_code}", "select": "id"},
            )
            if disease_res.status_code < 400:
                rows = disease_res.json()
                if rows:
                    payload["disease_id"] = rows[0]["id"]

            res = await client.post(
                f"{_SUPABASE_URL}/rest/v1/scans",
                headers=_headers(),
                json=payload,
            )
            if res.status_code >= 400:
                logger.warning("Scan insert failed: %s %s", res.status_code, res.text)
                return None
            rows = res.json()
            scan_id = rows[0]["id"] if rows else None
            if scan_id:
                await client.post(
                    f"{_SUPABASE_URL}/rest/v1/activity_logs",
                    headers=_headers(prefer="return=minimal"),
                    json={
                        "user_id": user_id,
                        "action": "api_detection",
                        "entity_type": "scan",
                        "entity_id": scan_id,
                        "metadata": {
                            "disease_code": disease_code,
                            "confidence": confidence,
                            "source": "backend",
                            "barangay": barangay,
                        },
                    },
                )
            return scan_id
    except Exception as exc:
        logger.warning("log_detection error: %s", exc)
        return None


async def log_chat_message(
    *,
    user_id: Optional[str],
    role: str,
    content: str,
    source: str = "agrismart_ai",
) -> None:
    """Persist chat turn to chat_messages + activity_logs."""
    if not is_configured() or not user_id or not content.strip():
        return

    try:
        async with httpx.AsyncClient(timeout=6.0) as client:
            await client.post(
                f"{_SUPABASE_URL}/rest/v1/chat_messages",
                headers=_headers(prefer="return=minimal"),
                json={
                    "user_id": user_id,
                    "role": role,
                    "content": content,
                    "source": source,
                },
            )
            if role == "user":
                await client.post(
                    f"{_SUPABASE_URL}/rest/v1/activity_logs",
                    headers=_headers(prefer="return=minimal"),
                    json={
                        "user_id": user_id,
                        "action": "chat_message",
                        "entity_type": "chat",
                        "metadata": {"preview": content[:120]},
                    },
                )
    except Exception as exc:
        logger.warning("log_chat_message error: %s", exc)
