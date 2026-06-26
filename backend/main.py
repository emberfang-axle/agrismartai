"""
AgriSmartAI :: Python HTTP Backend (stdlib only for the web server)
PostgreSQL + simulated MobileNetV2 disease detection + local Ka-Agro chat.
"""

from __future__ import annotations

import io
import json
import os
import re
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Dict, List, Optional, Tuple
from urllib.parse import parse_qs, urlparse

from ai_model.agrismart_chat import ChatTurn, chat as local_chat
from ai_model.simulate_detection import MODEL_VERSION, simulate_detection
from models import (
    AuthLoginRequest,
    AuthRegisterRequest,
    ChatMessage,
    ChatRequest,
    ChatResponse,
    DetectionResponse,
    DiseaseInfo,
    FeedbackRequest,
    HealthResponse,
    ReportCreateRequest,
    ReportStatusUpdate,
    UserResponse,
    ValidationResponse,
    to_json,
)

try:
    import db as pg
except ImportError:
    pg = None  # type: ignore

DISEASE_KB: Dict[str, DiseaseInfo] = {
    "bacterial_leaf_blight": DiseaseInfo(
        code="bacterial_leaf_blight",
        name="Bacterial Leaf Blight",
        scientific_name="Xanthomonas oryzae pv. oryzae",
        description="A serious bacterial disease causing wilting and drying of leaves.",
        symptoms="Water-soaked yellowish stripes, leaf tips turn gray and dry.",
        causes="Spread via irrigation water and rain.",
        treatment="Drain fields, remove infected stubble, apply copper-based bactericide.",
        fertilizer="Avoid excess nitrogen. Apply 90-60-60 NPK kg/ha.",
        prevention="Plant resistant varieties, use certified seeds.",
        da_directive="Report to Municipal Agriculture Office of New Bataan.",
        severity_label="High",
    ),
    "rice_blast": DiseaseInfo(
        code="rice_blast",
        name="Rice Blast",
        scientific_name="Magnaporthe oryzae",
        description="A destructive fungal disease affecting leaves and panicles.",
        symptoms="Diamond-shaped lesions with gray centers and brown margins.",
        causes="High humidity, cool nights, excessive nitrogen.",
        treatment="Apply tricyclazole fungicide at early lesion stage.",
        fertilizer="Reduce nitrogen to 80-60-60 NPK kg/ha. Apply silicon fertilizer.",
        prevention="Use blast-resistant varieties, avoid over-fertilizing nitrogen.",
        da_directive="Coordinate with DA-New Bataan for fungicide subsidy.",
        severity_label="High",
    ),
    "tungro": DiseaseInfo(
        code="tungro",
        name="Rice Tungro",
        scientific_name="Rice tungro bacilliform & spherical virus",
        description="A viral disease transmitted by green leafhoppers.",
        symptoms="Yellow to orange-yellow leaves, stunted growth.",
        causes="Spread by green leafhoppers.",
        treatment="Control leafhopper vectors; destroy infected plants.",
        fertilizer="Maintain balanced 90-60-60 NPK kg/ha.",
        prevention="Plant tungro-resistant varieties, synchronize planting.",
        da_directive="Notify DA-New Bataan immediately for vector surveillance.",
        severity_label="Severe",
    ),
    "healthy": DiseaseInfo(
        code="healthy",
        name="Healthy Rice Leaf",
        scientific_name="Oryza sativa",
        description="No disease detected. The rice leaf appears healthy.",
        symptoms="Uniform green color, no lesions or discoloration.",
        causes="N/A",
        treatment="Continue good agricultural practices.",
        fertilizer="Maintain balanced NPK based on soil test.",
        prevention="Continue field sanitation and weekly monitoring.",
        da_directive="No referral needed. Consult DA for seasonal advisories.",
        severity_label="None",
    ),
}


def _pg_ready() -> bool:
    return pg is not None and pg.is_configured() and pg.check_connection()


def validate_rice_leaf(image_bytes: bytes) -> ValidationResponse:
    if not image_bytes:
        return ValidationResponse(
            is_rice_leaf=False,
            reason="No image data received.",
            green_ratio=0.0,
            aspect_ratio=0.0,
        )
    try:
        from PIL import Image

        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        width, height = img.size
        if width < 64 or height < 64:
            return ValidationResponse(
                is_rice_leaf=False,
                reason="Image is too small. Upload a clearer photo.",
                green_ratio=0.0,
                aspect_ratio=1.0,
            )
        aspect_ratio = max(width, height) / max(1, min(width, height))
        img_small = img.resize((96, 96))
        pixels = list(img_small.getdata())
        green_pixels = sum(
            1
            for r, g, b in pixels
            if (g > r and g > b and g > 45) or (g > 80 and r < 180 and b < 120)
        )
        green_ratio = green_pixels / max(1, len(pixels))
        is_leaf = green_ratio >= 0.06
        return ValidationResponse(
            is_rice_leaf=is_leaf,
            reason="Valid image for analysis." if is_leaf else "Please upload a rice leaf photo.",
            green_ratio=round(green_ratio, 3),
            aspect_ratio=round(aspect_ratio, 3),
        )
    except Exception:
        return ValidationResponse(
            is_rice_leaf=True,
            reason="Image accepted for simulated analysis.",
            green_ratio=0.5,
            aspect_ratio=1.5,
        )


def _report_to_scan(row: dict) -> dict:
    return {
        "id": str(row["id"]),
        "user_id": str(row["user_id"]),
        "farmer_name": row.get("farmer_name") or "Unknown",
        "disease_code": row.get("disease_code") or "healthy",
        "disease_name": row.get("disease_label") or "Healthy",
        "disease_label": row.get("disease_label"),
        "confidence": float(row.get("confidence_score") or 0),
        "confidence_score": float(row.get("confidence_score") or 0),
        "barangay": row.get("barangay") or "New Bataan",
        "image_url": row.get("image_url"),
        "status": row.get("status") or "pending",
        "reviewer_note": row.get("reviewer_note"),
        "created_at": row["created_at"].isoformat() if row.get("created_at") else None,
    }


def _parse_json(body: bytes) -> dict:
    if not body:
        return {}
    return json.loads(body.decode("utf-8"))


def _parse_multipart(body: bytes, content_type: str) -> Tuple[Dict[str, str], Dict[str, bytes]]:
    if "boundary=" not in content_type:
        return {}, {}
    boundary = content_type.split("boundary=", 1)[1].strip().strip('"').encode()
    fields: Dict[str, str] = {}
    files: Dict[str, bytes] = {}
    for part in body.split(b"--" + boundary):
        if not part or part in (b"--\r\n", b"--", b"\r\n"):
            continue
        chunk = part[2:] if part.startswith(b"\r\n") else part
        if chunk.endswith(b"\r\n"):
            chunk = chunk[:-2]
        header_end = chunk.find(b"\r\n\r\n")
        if header_end == -1:
            continue
        headers = chunk[:header_end].decode("utf-8", errors="replace")
        data = chunk[header_end + 4 :]
        name_match = re.search(r'name="([^"]+)"', headers)
        if not name_match:
            continue
        name = name_match.group(1)
        if 'filename="' in headers:
            files[name] = data
        else:
            fields[name] = data.decode("utf-8", errors="replace")
    return fields, files


def _dataclass_from_dict(cls, data: dict):
    return cls(**{k: v for k, v in data.items() if k in cls.__dataclass_fields__})


class AgriRequestHandler(BaseHTTPRequestHandler):
    server_version = "AgriSmartAI/2.0"

    def log_message(self, fmt: str, *args) -> None:
        print(f"[backend] {self.address_string()} - {fmt % args}")

    def _cors(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PATCH, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def _send_json(self, status: int, payload: object) -> None:
        body = json.dumps(to_json(payload)).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self._cors()
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_error_json(self, status: int, detail: str) -> None:
        self._send_json(status, {"detail": detail})

    def _read_body(self) -> bytes:
        length = int(self.headers.get("Content-Length", 0))
        return self.rfile.read(length) if length else b""

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/") or "/"
        query = parse_qs(parsed.query)

        if path == "/":
            self._send_json(
                200,
                {
                    "service": "AgriSmartAI Backend",
                    "database": "PostgreSQL",
                    "location": "New Bataan, Davao de Oro, Philippines",
                    "runtime": "Python HTTP server",
                },
            )
            return

        if path == "/api/health":
            self._send_json(
                200,
                HealthResponse(
                    model_version=MODEL_VERSION,
                    ai_chat_enabled=True,
                    postgresql_enabled=_pg_ready(),
                ),
            )
            return

        if path == "/api/reports":
            user_id = query.get("user_id", [None])[0]
            if not _pg_ready():
                self._send_json(200, [])
                return
            rows = pg.fetch_reports(user_id)
            self._send_json(200, [_report_to_scan(r) for r in rows])
            return

        if path == "/api/farmers":
            self._send_json(200, pg.fetch_farmers() if _pg_ready() else [])
            return

        if path == "/api/feedback":
            self._send_json(200, pg.fetch_feedback() if _pg_ready() else [])
            return

        if path == "/api/disease-stats":
            self._send_json(200, pg.disease_stats() if _pg_ready() else [])
            return

        if path == "/api/dashboard/stats":
            if not _pg_ready():
                self._send_json(
                    200,
                    {"farmers": 0, "scans": 0, "pending": 0, "verified": 0, "by_disease": []},
                )
                return
            self._send_json(200, pg.dashboard_stats())
            return

        self._send_error_json(404, "Not found")

    def do_POST(self) -> None:
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")
        body = self._read_body()
        content_type = self.headers.get("Content-Type", "")

        try:
            if path == "/api/auth/register":
                req = _dataclass_from_dict(AuthRegisterRequest, _parse_json(body))
                if not _pg_ready():
                    self._send_error_json(503, "PostgreSQL not connected. Using offline demo mode in app.")
                    return
                user = pg.register_user(req.name, req.email, req.password, req.barangay)
                self._send_json(
                    200,
                    UserResponse(
                        id=user["id"],
                        full_name=user["full_name"],
                        email=user["email"],
                        role=user["role"],
                        barangay=user["barangay"],
                    ),
                )
                return

            if path == "/api/auth/login":
                req = _dataclass_from_dict(AuthLoginRequest, _parse_json(body))
                if not _pg_ready():
                    self._send_error_json(503, "PostgreSQL not connected.")
                    return
                user = pg.login_user(req.email, req.password)
                if not user:
                    self._send_error_json(401, "Invalid email or password.")
                    return
                self._send_json(
                    200,
                    UserResponse(
                        id=user["id"],
                        full_name=user["full_name"],
                        email=user["email"],
                        role=user["role"],
                        barangay=user["barangay"],
                    ),
                )
                return

            if path == "/api/reports":
                req = _dataclass_from_dict(ReportCreateRequest, _parse_json(body))
                if not _pg_ready():
                    self._send_error_json(503, "PostgreSQL not connected.")
                    return
                report_id = pg.create_report(
                    user_id=req.user_id,
                    disease_code=req.disease_code,
                    disease_label=req.disease_label,
                    confidence=req.confidence_score,
                    barangay=req.barangay,
                    location=req.location,
                )
                self._send_json(
                    200,
                    {
                        "id": report_id,
                        **{k: getattr(req, k) for k in req.__dataclass_fields__},
                        "created_at": None,
                    },
                )
                return

            if path == "/api/feedback":
                req = _dataclass_from_dict(FeedbackRequest, _parse_json(body))
                if not _pg_ready():
                    self._send_json(200, {"ok": True})
                    return
                with pg.get_conn() as conn:
                    with conn.cursor() as cur:
                        cur.execute(
                            "INSERT INTO feedback (user_id, rating, comment) VALUES (%s, %s, %s)",
                            (req.user_id, req.rating, req.comment),
                        )
                self._send_json(200, {"ok": True})
                return

            if path == "/api/chat":
                data = _parse_json(body)
                history = [
                    ChatMessage(role=m["role"], content=m["content"])
                    for m in data.get("history", [])[-8:]
                ]
                req = ChatRequest(
                    message=data.get("message", ""),
                    history=history,
                    context_disease=data.get("context_disease"),
                    user_id=data.get("user_id"),
                )
                result = local_chat(
                    message=req.message,
                    history=[ChatTurn(role=m.role, content=m.content) for m in req.history],
                    context_disease=req.context_disease,
                )
                self._send_json(
                    200,
                    ChatResponse(
                        reply=result.reply,
                        source=result.source,
                        confidence=result.confidence,
                    ),
                )
                return

            if path == "/api/validate":
                _, files = _parse_multipart(body, content_type)
                image_bytes = files.get("file", b"")
                self._send_json(200, validate_rice_leaf(image_bytes))
                return

            if path == "/api/detect":
                fields, files = _parse_multipart(body, content_type)
                image_bytes = files.get("file", b"")
                if not image_bytes:
                    self._send_json(
                        200,
                        DetectionResponse(
                            disease_code="healthy",
                            disease_name="Invalid Image",
                            confidence=0.0,
                            is_rice_leaf=False,
                            model_version=MODEL_VERSION,
                            probabilities={},
                            message="No image file received.",
                            disease_info=DISEASE_KB.get("healthy"),
                            scan_id=None,
                        ),
                    )
                    return

                result = simulate_detection(
                    image_bytes,
                    is_rice_leaf=True,
                    forced_class=fields.get("force_class") or None,
                )
                info = DISEASE_KB.get(result.disease_code)
                scan_id = None
                user_id = fields.get("user_id", "")
                barangay = fields.get("barangay", "New Bataan")
                if _pg_ready() and user_id:
                    try:
                        scan_id = pg.create_report(
                            user_id=user_id,
                            disease_code=result.disease_code,
                            disease_label=result.disease_name,
                            confidence=result.confidence,
                            barangay=barangay,
                        )
                    except Exception:
                        pass

                self._send_json(
                    200,
                    DetectionResponse(
                        disease_code=result.disease_code,
                        disease_name=result.disease_name,
                        confidence=result.confidence,
                        is_rice_leaf=result.is_rice_leaf,
                        model_version=result.model_version,
                        probabilities=result.probabilities,
                        message=result.message,
                        disease_info=info,
                        scan_id=scan_id,
                    ),
                )
                return

            self._send_error_json(404, "Not found")
        except json.JSONDecodeError:
            self._send_error_json(400, "Invalid JSON body")
        except Exception as exc:
            self._send_error_json(400, str(exc))

    def do_PATCH(self) -> None:
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")
        match = re.fullmatch(r"/api/reports/([^/]+)/status", path)
        if not match:
            self._send_error_json(404, "Not found")
            return

        report_id = match.group(1)
        try:
            body = _dataclass_from_dict(ReportStatusUpdate, _parse_json(self._read_body()))
            if not _pg_ready():
                self._send_error_json(503, "PostgreSQL not connected.")
                return
            ok = pg.update_report_status(
                report_id, body.status, reviewer_note=body.reviewer_note
            )
            if not ok:
                self._send_error_json(404, "Report not found.")
                return
            self._send_json(
                200,
                {"id": report_id, "status": body.status, "reviewer_note": body.reviewer_note},
            )
        except json.JSONDecodeError:
            self._send_error_json(400, "Invalid JSON body")
        except Exception as exc:
            self._send_error_json(400, str(exc))

    def do_DELETE(self) -> None:
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")
        match = re.fullmatch(r"/api/reports/([^/]+)", path)
        if not match:
            self._send_error_json(404, "Not found")
            return

        report_id = match.group(1)
        query = parse_qs(parsed.query)
        user_id = query.get("user_id", [""])[0]
        if not _pg_ready():
            self._send_json(200, {"deleted": True})
            return
        ok = pg.delete_report(report_id, user_id)
        self._send_json(200, {"deleted": ok})


def _seed_admin() -> None:
    if _pg_ready():
        try:
            pg.seed_admin()
        except Exception:
            pass


def run_server(host: str = "0.0.0.0", port: Optional[int] = None) -> None:
    _seed_admin()
    listen_port = port or int(os.getenv("PORT", "8000"))
    server = HTTPServer((host, listen_port), AgriRequestHandler)
    print(f"AgriSmartAI Python backend listening on http://{host}:{listen_port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down backend.")
        server.server_close()


if __name__ == "__main__":
    run_server()
