"""Chat service — DeepSeek API with Taglish-aware fallbacks."""

import json
from typing import Any

import httpx

from app.core.config import settings
from app.core.prompts import FARMING_ASSISTANT_PROMPT


class ChatService:
    def build_messages(
        self,
        history: list[dict[str, str]],
        scan_context: dict[str, Any] | None = None,
    ) -> list[dict[str, str]]:
        messages: list[dict[str, str]] = [
            {"role": "system", "content": FARMING_ASSISTANT_PROMPT},
        ]
        if scan_context:
            disease = scan_context.get("disease", "Unknown")
            confidence = scan_context.get("confidence", 0)
            severity = scan_context.get("severity", "Mild")
            messages.append({
                "role": "system",
                "content": (
                    f"RECENT SCAN CONTEXT: Disease={disease}, "
                    f"Confidence={confidence:.0%}, Severity={severity}. "
                    "Reference this when the farmer asks about their result."
                ),
            })
        messages.extend(history)
        return messages

    async def chat(
        self,
        history: list[dict[str, str]],
        scan_context: dict[str, Any] | None = None,
    ) -> str:
        if not settings.deepseek_api_key:
            return self._fallback(history, scan_context)

        messages = self.build_messages(history, scan_context)
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    settings.deepseek_api_url,
                    headers={
                        "Content-Type": "application/json",
                        "Authorization": f"Bearer {settings.deepseek_api_key}",
                    },
                    json={
                        "model": settings.deepseek_model,
                        "messages": messages,
                        "temperature": 0.7,
                        "max_tokens": 600,
                    },
                )
                if response.status_code == 200:
                    data = response.json()
                    return data["choices"][0]["message"]["content"]
        except Exception:
            pass

        return self._fallback(history, scan_context)

    def _fallback(
        self,
        history: list[dict[str, str]],
        scan_context: dict[str, Any] | None,
    ) -> str:
        last = history[-1]["content"].lower() if history else ""
        disease = (scan_context or {}).get("disease", "")

        if any(w in last for w in ["ano", "what", "cause", "sanhi"]):
            if disease:
                return (
                    f"Ang {disease} ay common sa rice fields lalo na kapag maulan at basa ang paddies. "
                    "Kumakalat ito sa tubig, hangin, o infected seeds. "
                    "Tanggalin agad ang may sakit na dahon at i-report sa DA para ma-verify."
                )
            return (
                "Ang rice diseases ay kumakalat sa pamamagitan ng tubig, leafhoppers, at infected seeds. "
                "Early detection ang susi — mag-scan weekly gamit ang AgriSmartAI."
            )

        if any(w in last for w in ["treat", "gamot", "ano gagawin", "how"]):
            return (
                "1) Ayusin ang drainage ng field\n"
                "2) Sundin ang fertilizer recommendation sa scan result\n"
                "3) Gumamit ng DA-approved fungicide/bactericide kung kailangan\n"
                "4) Pumunta sa DA office sa Bago Oshiro, Davao City para sa libreng konsulta"
            )

        if any(w in last for w in ["spread", "kumakalat", "contagious"]):
            return (
                "Oo, mabilis kumalat ang sakit sa flooded fields. "
                "I-isolate ang infected area, huwag mag-share ng tools, "
                "at mag-scout araw-araw sa katabing puno."
            )

        if any(w in last for w in ["da", "consult", "konsulta", "office"]):
            return (
                "Oo, recommended po! DA RFO XI — (082) 123-4567, Mon–Fri 8AM–5PM. "
                "Libre ang field verification at approved input recommendations."
            )

        if disease:
            return (
                f"Base sa scan mo, nakita natin ang **{disease}**. "
                "Tanungin mo ako: 'Paano i-treat?' o 'Kailangan ba pumunta sa DA?' "
                "— tutulungan kita step by step."
            )

        return (
            "Kumusta! Ako si AgriSmartAI, rice farming assistant mo. "
            "Pwede kang magtanong sa Taglish o English about diseases, treatment, "
            "fertilizer, o kung kailan dapat pumunta sa DA office."
        )
