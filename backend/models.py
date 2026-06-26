"""
AgriSmartAI :: Pydantic request/response models for the FastAPI backend.
"""

from __future__ import annotations

from typing import Dict, List, Optional

from pydantic import BaseModel, Field


class DetectionResponse(BaseModel):
    disease_code: str = Field(..., examples=["rice_blast"])
    disease_name: str = Field(..., examples=["Rice Blast"])
    confidence: float = Field(..., ge=0, le=100, examples=[91.4])
    is_rice_leaf: bool = True
    model_version: str = "mobilenetv2-sim-1.0"
    probabilities: Dict[str, float] = Field(default_factory=dict)
    message: str = ""
    disease_info: Optional["DiseaseInfo"] = None
    scan_id: Optional[str] = None


class DiseaseInfo(BaseModel):
    code: str
    name: str
    scientific_name: str = ""
    description: str = ""
    symptoms: str = ""
    causes: str = ""
    treatment: str = ""
    fertilizer: str = ""
    prevention: str = ""
    da_directive: str = ""
    severity_label: str = "Moderate"


class ValidationResponse(BaseModel):
    is_rice_leaf: bool
    reason: str = ""
    green_ratio: float = 0.0
    aspect_ratio: float = 0.0


class ChatMessage(BaseModel):
    role: str = Field(..., examples=["user", "assistant"])
    content: str


class ChatRequest(BaseModel):
    message: str
    history: List[ChatMessage] = Field(default_factory=list)
    context_disease: Optional[str] = None
    user_id: Optional[str] = None


class ChatResponse(BaseModel):
    reply: str
    source: str = "agrismart_ai"
    confidence: float = 0.0


class HealthResponse(BaseModel):
    status: str = "ok"
    service: str = "AgriSmartAI Backend"
    model_version: str = "mobilenetv2-sim-1.0"
    ai_chat_enabled: bool = True
    postgresql_enabled: bool = False


class AuthRegisterRequest(BaseModel):
    name: str
    email: str
    password: str
    barangay: str = "New Bataan"


class AuthLoginRequest(BaseModel):
    email: str
    password: str


class UserResponse(BaseModel):
    id: str
    full_name: str
    email: str
    role: str = "farmer"
    barangay: str = "New Bataan"


class ReportCreateRequest(BaseModel):
    user_id: str
    disease_code: str
    disease_label: str
    confidence_score: float
    barangay: str = "New Bataan"
    location: Optional[str] = None


class ReportStatusUpdate(BaseModel):
    status: str
    reviewer_note: Optional[str] = None
    user_id: str
    rating: int = Field(ge=1, le=5)
    comment: Optional[str] = None


DetectionResponse.model_rebuild()
