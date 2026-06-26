"""
AgriSmartAI :: Request/response models for the Python HTTP backend.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any, Dict, List, Optional


def to_json(obj: Any) -> Any:
    if hasattr(obj, "__dataclass_fields__"):
        return {k: to_json(v) for k, v in asdict(obj).items()}
    if isinstance(obj, dict):
        return {k: to_json(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [to_json(v) for v in obj]
    return obj


@dataclass
class DiseaseInfo:
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


@dataclass
class DetectionResponse:
    disease_code: str
    disease_name: str
    confidence: float
    is_rice_leaf: bool = True
    model_version: str = "mobilenetv2-sim-1.0"
    probabilities: Dict[str, float] = field(default_factory=dict)
    message: str = ""
    disease_info: Optional[DiseaseInfo] = None
    scan_id: Optional[str] = None


@dataclass
class ValidationResponse:
    is_rice_leaf: bool
    reason: str = ""
    green_ratio: float = 0.0
    aspect_ratio: float = 0.0


@dataclass
class ChatMessage:
    role: str
    content: str


@dataclass
class ChatRequest:
    message: str
    history: List[ChatMessage] = field(default_factory=list)
    context_disease: Optional[str] = None
    user_id: Optional[str] = None


@dataclass
class ChatResponse:
    reply: str
    source: str = "agrismart_ai"
    confidence: float = 0.0


@dataclass
class HealthResponse:
    status: str = "ok"
    service: str = "AgriSmartAI Backend"
    model_version: str = "mobilenetv2-sim-1.0"
    ai_chat_enabled: bool = True
    postgresql_enabled: bool = False


@dataclass
class AuthRegisterRequest:
    name: str
    email: str
    password: str
    barangay: str = "New Bataan"


@dataclass
class AuthLoginRequest:
    email: str
    password: str


@dataclass
class UserResponse:
    id: str
    full_name: str
    email: str
    role: str = "farmer"
    barangay: str = "New Bataan"


@dataclass
class ReportCreateRequest:
    user_id: str
    disease_code: str
    disease_label: str
    confidence_score: float
    barangay: str = "New Bataan"
    location: Optional[str] = None


@dataclass
class ReportStatusUpdate:
    status: str
    reviewer_note: Optional[str] = None


@dataclass
class FeedbackRequest:
    user_id: str
    rating: int
    comment: Optional[str] = None
