from fastapi import APIRouter

from app.core.config import settings
from app.services.model_loader import get_model

router = APIRouter(tags=["health"])


@router.get("/")
async def root():
    return {
        "app": settings.app_name,
        "version": settings.app_version,
        "status": "online",
        "model": "mobilenetv2" if get_model() else "simulated",
    }


@router.get("/health")
async def health():
    return {
        "status": "healthy",
        "model": "mobilenetv2" if get_model() else "simulated",
    }
