"""Application configuration."""

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    app_name: str = "AgriSmartAI API"
    app_version: str = "1.0.0"
    model_path: str = os.environ.get("MODEL_PATH", "models/mobilenetv2_rice.h5")
    deepseek_api_key: str = os.environ.get("DEEPSEEK_API_KEY", "")
    deepseek_api_url: str = "https://api.deepseek.com/chat/completions"
    deepseek_model: str = "deepseek-chat"
    cors_origins: list[str] = None  # type: ignore[assignment]

    def __post_init__(self) -> None:
        if self.cors_origins is None:
            object.__setattr__(self, "cors_origins", ["*"])


settings = Settings()
