"""
AgriSmartAI :: Local conversational AI (no external APIs).
================================================================================
OBJECTIVE 3: App + fertilizer + DA referral  (answers from knowledge base)
OBJECTIVE 4: Farmer evaluation + admin board  (works fully offline)

Uses keyword-scored QA pairs + disease context — behaves like a chat assistant
without calling ChatGPT, DeepSeek, or any third-party LLM API.
"""

from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass, field
from typing import List, Optional

# Default knowledge file (copied from farmer QA dataset).
_KB_PATH = os.path.join(os.path.dirname(__file__), "knowledge", "qa_pairs.json")

# In-memory cache after first load.
_QA_CACHE: list[dict] | None = None


@dataclass
class ChatTurn:
    role: str  # 'user' | 'assistant'
    content: str


@dataclass
class ChatResult:
    reply: str
    source: str = "agrismart_ai"
    matched_topic: str = ""
    confidence: float = 0.0


def _normalize(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^\w\s]", " ", text)
    return re.sub(r"\s+", " ", text)


def _load_qa() -> list[dict]:
    global _QA_CACHE
    if _QA_CACHE is not None:
        return _QA_CACHE
    if not os.path.isfile(_KB_PATH):
        _QA_CACHE = []
        return _QA_CACHE
    with open(_KB_PATH, encoding="utf-8") as f:
        _QA_CACHE = json.load(f)
    return _QA_CACHE


def _score_entry(message: str, entry: dict, context_disease: str | None) -> float:
    """Score how well a QA entry matches the user message."""
    norm = _normalize(message)
    if not norm:
        return 0.0

    score = 0.0
    keywords: list[str] = entry.get("keywords") or []
    for kw in keywords:
        kw_norm = _normalize(kw)
        if kw_norm and kw_norm in norm:
            score += 3.0 + len(kw_norm.split()) * 0.5

    question = _normalize(entry.get("question") or "")
    for token in question.split():
        if len(token) > 3 and token in norm:
            score += 0.8

    # Boost entries related to the last detected disease (context awareness).
    if context_disease:
        ctx = context_disease.replace("_", " ")
        answer = (entry.get("answer") or "").lower()
        if ctx in answer or ctx in " ".join(keywords).lower():
            score += 2.5

    return score


def _greeting_reply() -> str:
    return (
        "Kumusta! Ako si Ka-Agro — inyong AgriSmartAI rice expert para sa New Bataan. "
        "Pangutana bahin sa Bacterial Leaf Blight, Rice Blast, Tungro, abono, "
        "resistant varieties, o DA office. Mag-scan una sa dahon para mas accurate!"
    )


def _context_reply(context_disease: str, message: str) -> str | None:
    """Short answers when we know the farmer's last scan result."""
    norm = _normalize(message)
    ctx_map = {
        "bacterial_leaf_blight": "Bacterial Leaf Blight",
        "rice_blast": "Rice Blast",
        "tungro": "Rice Tungro",
        "healthy": "Healthy Rice Leaf",
    }
    name = ctx_map.get(context_disease, context_disease)

    if any(w in norm for w in ["fertilizer", "abono", "npk"]):
        return (
            f"For your recent {name} detection: avoid excess nitrogen, use balanced "
            "90-60-60 NPK kg/ha split into 3 doses, and add potassium if leaves are weak."
        )
    if any(w in norm for w in ["treat", "cure", "gamot", "control", "spray"]):
        return (
            f"For {name}: follow DA-recommended treatment — drain fields, remove infected "
            "stubble, and apply the correct fungicide/bactericide at early stage."
        )
    if any(w in norm for w in ["da", "agriculture", "refer", "report"]):
        return (
            f"For {name}, report to the Municipal Agriculture Office of New Bataan "
            "for technician inspection and resistant-seed or input assistance."
        )
    return None


def chat(
    message: str,
    history: Optional[List[ChatTurn]] = None,
    context_disease: Optional[str] = None,
) -> ChatResult:
    """
    Generate a reply using the local AgriSmartAI knowledge engine.

    Args:
        message: User's latest question.
        history: Recent conversation turns (used for follow-up detection).
        context_disease: Last detected disease code from a scan.
    """
    text = (message or "").strip()
    if not text:
        return ChatResult(reply="Please type a question about your rice crop.", confidence=0.0)

    norm = _normalize(text)

    # Greetings
    if any(w in norm for w in ["hello", "hi", "kumusta", "kamusta", "good morning", "magandang"]):
        return ChatResult(reply=_greeting_reply(), matched_topic="greeting", confidence=0.95)

    if any(w in norm for w in ["thank", "salamat"]):
        return ChatResult(
            reply="You're welcome! Keep monitoring your field and scan leaves weekly.",
            matched_topic="thanks",
            confidence=0.9,
        )

    # Score all QA entries FIRST (before context shortcut — fixes repetitive replies).
    qa = _load_qa()
    best: dict | None = None
    best_score = 0.0
    for entry in qa:
        s = _score_entry(text, entry, context_disease)
        if s > best_score:
            best_score = s
            best = entry

    if best and best_score >= 2.0:
        conf = min(0.98, 0.55 + best_score * 0.06)
        return ChatResult(
            reply=best["answer"],
            matched_topic=best.get("question", ""),
            confidence=round(conf, 2),
        )

    # Context-aware shortcut only when no specific QA match.
    if context_disease and context_disease != "healthy":
        ctx_reply = _context_reply(context_disease, text)
        if ctx_reply:
            return ChatResult(
                reply=ctx_reply,
                matched_topic=context_disease,
                confidence=0.88,
            )

    # Removed duplicate QA scoring block — handled above.

    # Follow-up: repeat last assistant topic if user says "tell me more"
    if history and any(w in norm for w in ["more", "explain", "detailed", "pa explain"]):
        for turn in reversed(history):
            if turn.role == "assistant" and len(turn.content) > 40:
                return ChatResult(
                    reply=turn.content,
                    matched_topic="follow_up",
                    confidence=0.7,
                )

    return ChatResult(
        reply=(
            "Pasensya na, wala pa sa akong knowledge base ang inyong pangutana. "
            "Try: 'Unsa ni nga sakit?', 'Unsa ang abono?', 'Unsa nga klase sa humay?', "
            "o 'Asa ang DA office?'"
        ),
        matched_topic="fallback",
        confidence=0.4,
    )


if __name__ == "__main__":
    samples = [
        "What is rice blast?",
        "What fertilizer for rice?",
        "How do I report to DA?",
    ]
    for q in samples:
        r = chat(q)
        print(f"Q: {q}\nA ({r.confidence}): {r.reply[:120]}...\n")
