"""Detection service — validates rice leaf, then predicts disease."""

from fastapi import HTTPException

from app.core.detection import predict_from_image, simulate_detection
from app.core.rice_validation import validate_rice_leaf
from app.services.model_loader import get_model


class DetectionService:
    def validate(self, image_bytes: bytes) -> dict:
        result = validate_rice_leaf(image_bytes)
        return {
            "is_valid": result.is_valid,
            "message": result.message,
            "green_ratio": round(result.green_ratio, 4),
            "score": round(result.score, 4),
        }

    def predict(self, image_bytes: bytes) -> dict:
        validation = validate_rice_leaf(image_bytes)
        if not validation.is_valid:
            raise HTTPException(
                status_code=422,
                detail={
                    "error": "not_rice_leaf",
                    "message": validation.message,
                    "green_ratio": round(validation.green_ratio, 4),
                },
            )
        prediction = predict_from_image(image_bytes, get_model())
        prediction["validation"] = {
            "green_ratio": round(validation.green_ratio, 4),
            "score": round(validation.score, 4),
        }
        return prediction

    def simulate(self) -> dict:
        return simulate_detection()
