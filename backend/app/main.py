"""AgriSmartAI FastAPI — application factory."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import chat, health, predict
from app.core.config import settings
from app.services.model_loader import load_model


@asynccontextmanager
async def lifespan(_app: FastAPI):
    load_model()
    yield


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="Rice disease detection & AI farming assistant API",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health.router)
    app.include_router(predict.router)
    app.include_router(chat.router)

    return app
