"""Load and cache the TensorFlow disease model."""

import os
from typing import Any

from app.core.config import settings

_model: Any | None = None


def get_model() -> Any | None:
    return _model


def load_model() -> Any | None:
    global _model
    path = settings.model_path
    if not os.path.exists(path):
        print(f"[AgriSmartAI] No model at {path} — simulation mode")
        return None
    try:
        from tensorflow.keras.models import load_model as keras_load

        _model = keras_load(path)
        print("[AgriSmartAI] MobileNetV2 model loaded")
        return _model
    except Exception as exc:
        print(f"[AgriSmartAI] Model load failed: {exc} — simulation mode")
        return None
