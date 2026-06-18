from typing import Any

from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.services.chat_service import ChatService

router = APIRouter(prefix="/chat", tags=["chat"])
_chat = ChatService()


class ChatMessage(BaseModel):
    role: str = Field(..., pattern="^(user|assistant)$")
    content: str


class ChatRequest(BaseModel):
    messages: list[ChatMessage]
    scan_context: dict[str, Any] | None = None


class ChatResponse(BaseModel):
    reply: str


@router.post("", response_model=ChatResponse)
async def chat(request: ChatRequest):
    history = [{"role": m.role, "content": m.content} for m in request.messages]
    reply = await _chat.chat(history, request.scan_context)
    return ChatResponse(reply=reply)
