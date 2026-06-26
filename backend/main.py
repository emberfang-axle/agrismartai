"""
AgriSmartAI :: FastAPI Backend
PostgreSQL + Simulated MobileNetV2 disease detection + Local Ka-Agro chat.
"""

from __future__ import annotations

import io
import os
from typing import Dict

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from ai_model.agrismart_chat import ChatTurn, chat as local_chat
from ai_model.simulate_detection import MODEL_VERSION, simulate_detection
from models import (
    AuthLoginRequest,
    AuthRegisterRequest,
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
)

try:
    import db as pg
except ImportError:
    pg = None  # type: ignore

app = FastAPI(
    title="AgriSmartAI Backend",
    description="Rice crop disease detection API for New Bataan, Davao de Oro.",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

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


@app.on_event("startup")
def startup() -> None:
    if _pg_ready():
        try:
            pg.seed_admin()
        except Exception:
            pass


@app.get("/")
def root() -> dict:
    return {
        "service": "AgriSmartAI Backend",
        "database": "PostgreSQL",
        "location": "New Bataan, Davao de Oro, Philippines",
        "docs": "/docs",
    }


@app.get("/api/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(
        model_version=MODEL_VERSION,
        ai_chat_enabled=True,
        postgresql_enabled=_pg_ready(),
    )


@app.post("/api/auth/register", response_model=UserResponse)
def register(req: AuthRegisterRequest) -> UserResponse:
    if not _pg_ready():
        raise HTTPException(503, "PostgreSQL not connected. Using offline demo mode in app.")
    try:
        user = pg.register_user(req.name, req.email, req.password, req.barangay)
        return UserResponse(
            id=user["id"],
            full_name=user["full_name"],
            email=user["email"],
            role=user["role"],
            barangay=user["barangay"],
        )
    except Exception as e:
        raise HTTPException(400, f"Registration failed: {e}") from e


@app.post("/api/auth/login", response_model=UserResponse)
def login(req: AuthLoginRequest) -> UserResponse:
    if not _pg_ready():
        raise HTTPException(503, "PostgreSQL not connected.")
    user = pg.login_user(req.email, req.password)
    if not user:
        raise HTTPException(401, "Invalid email or password.")
    return UserResponse(
        id=user["id"],
        full_name=user["full_name"],
        email=user["email"],
        role=user["role"],
        barangay=user["barangay"],
    )


@app.get("/api/reports")
def list_reports(user_id: str | None = None) -> list:
    if not _pg_ready():
        return []
    rows = pg.fetch_reports(user_id)
    return [_report_to_scan(r) for r in rows]


@app.post("/api/reports")
def create_report(req: ReportCreateRequest) -> dict:
    if not _pg_ready():
        raise HTTPException(503, "PostgreSQL not connected.")
    report_id = pg.create_report(
        user_id=req.user_id,
        disease_code=req.disease_code,
        disease_label=req.disease_label,
        confidence=req.confidence_score,
        barangay=req.barangay,
        location=req.location,
    )
    return {"id": report_id, **req.model_dump(), "created_at": None}


@app.patch("/api/reports/{report_id}/status")
def update_report_status(report_id: str, body: ReportStatusUpdate) -> dict:
    if not _pg_ready():
        raise HTTPException(503, "PostgreSQL not connected.")
    ok = pg.update_report_status(
        report_id, body.status, reviewer_note=body.reviewer_note
    )
    if not ok:
        raise HTTPException(404, "Report not found.")
    return {"id": report_id, "status": body.status, "reviewer_note": body.reviewer_note}


@app.get("/api/farmers")
def list_farmers() -> list:
    if not _pg_ready():
        return []
    return pg.fetch_farmers()


@app.get("/api/feedback")
def list_feedback() -> list:
    if not _pg_ready():
        return []
    return pg.fetch_feedback()


@app.get("/api/disease-stats")
def disease_stats() -> list:
    if not _pg_ready():
        return []
    return pg.disease_stats()


@app.delete("/api/reports/{report_id}")
def delete_report(report_id: str, user_id: str) -> dict:
    if not _pg_ready():
        return {"deleted": True}
    ok = pg.delete_report(report_id, user_id)
    return {"deleted": ok}


@app.post("/api/feedback")
def submit_feedback(req: FeedbackRequest) -> dict:
    if not _pg_ready():
        return {"ok": True}
    with pg.get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO feedback (user_id, rating, comment) VALUES (%s, %s, %s)",
                (req.user_id, req.rating, req.comment),
            )
    return {"ok": True}


@app.get("/api/dashboard/stats")
def dashboard_stats() -> dict:
    if not _pg_ready():
        return {"farmers": 0, "scans": 0, "pending": 0, "verified": 0, "by_disease": []}
    return pg.dashboard_stats()


@app.post("/api/validate", response_model=ValidationResponse)
async def validate(file: UploadFile = File(...)) -> ValidationResponse:
    return validate_rice_leaf(await file.read())


@app.post("/api/detect", response_model=DetectionResponse)
async def detect(
    file: UploadFile = File(...),
    force_class: str = Form(default=""),
    user_id: str = Form(default=""),
    barangay: str = Form(default="New Bataan"),
    latitude: str = Form(default=""),
    longitude: str = Form(default=""),
) -> DetectionResponse:
    image_bytes = await file.read()
    if not image_bytes:
        return DetectionResponse(
            disease_code="healthy",
            disease_name="Invalid Image",
            confidence=0.0,
            is_rice_leaf=False,
            model_version=MODEL_VERSION,
            probabilities={},
            message="No image file received.",
            disease_info=DISEASE_KB.get("healthy"),
            scan_id=None,
        )

    validation = validate_rice_leaf(image_bytes)
    result = simulate_detection(
        image_bytes,
        is_rice_leaf=True,
        forced_class=force_class or None,
    )
    info = DISEASE_KB.get(result.disease_code)

    scan_id = None
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

    return DetectionResponse(
        disease_code=result.disease_code,
        disease_name=result.disease_name,
        confidence=result.confidence,
        is_rice_leaf=result.is_rice_leaf,
        model_version=result.model_version,
        probabilities=result.probabilities,
        message=result.message,
        disease_info=info,
        scan_id=scan_id,
    )


@app.post("/api/chat", response_model=ChatResponse)
async def chat_endpoint(req: ChatRequest) -> ChatResponse:
    history = [ChatTurn(role=m.role, content=m.content) for m in req.history[-8:]]
    result = local_chat(
        message=req.message,
        history=history,
        context_disease=req.context_disease,
    )
    return ChatResponse(
        reply=result.reply,
        source=result.source,
        confidence=result.confidence,
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=int(os.getenv("PORT", "8000")), reload=True)
