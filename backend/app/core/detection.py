"""Disease detection core logic — simulation + MobileNetV2 inference."""

import random
from typing import Any

DISEASES = ["BLB", "Blast", "Tungro", "Healthy"]

DISPLAY_NAMES = {
    "BLB": "Bacterial Leaf Blight",
    "Blast": "Rice Blast",
    "Tungro": "Tungro",
    "Healthy": "Healthy",
}

TREATMENT_TIPS: dict[str, tuple[str, str]] = {
    "BLB": (
        "Reduce nitrogen by 30% and apply muriate of potash (40 kg/ha).",
        "Drain flooded fields and remove infected leaves immediately.",
    ),
    "Blast": (
        "Apply silicon-based fertilizer (calcium silicate 200 kg/ha).",
        "Use balanced NPK 14-14-14 and spray tricyclazole per DA advice.",
    ),
    "Tungro": (
        "Apply balanced NPK with extra potassium.",
        "Control green leafhoppers with recommended insecticide.",
    ),
    "Healthy": (
        "Continue regular NPK schedule at tillering stage.",
        "Maintain proper water level and monitor weekly.",
    ),
}


def _build_result(disease: str, confidence: float, model: str) -> dict[str, Any]:
    severe = confidence >= 0.88
    fert, mgmt = TREATMENT_TIPS[disease]
    return {
        "disease": disease,
        "display_name": DISPLAY_NAMES[disease],
        "confidence": round(confidence, 4),
        "confidence_percent": f"{confidence * 100:.1f}%",
        "severity": "Severe" if severe else "Mild",
        "fertilizer_tip": fert,
        "management_tip": mgmt,
        "fertilizer_recommendations": [fert, mgmt],
        "da_message": (
            "Please consult DA RFO XI at DA Compound, Bago Oshiro, Davao City "
            "for field verification and approved input recommendations."
        ),
        "model": model,
    }


def simulate_detection() -> dict[str, Any]:
    disease = random.choice(DISEASES)
    confidence = random.uniform(0.70, 0.98)
    return _build_result(disease, confidence, "simulated")


def predict_from_image(image_bytes: bytes, model: Any | None) -> dict[str, Any]:
    if model is None:
        return simulate_detection()

    try:
        import io
        import numpy as np
        from PIL import Image

        img = Image.open(io.BytesIO(image_bytes)).convert("RGB").resize((224, 224))
        arr = np.array(img, dtype=np.float32) / 255.0
        arr = np.expand_dims(arr, axis=0)
        preds = model.predict(arr, verbose=0)[0]
        idx = int(np.argmax(preds))
        confidence = float(preds[idx])
        disease = DISEASES[idx] if idx < len(DISEASES) else DISEASES[0]
        return _build_result(disease, confidence, "mobilenetv2")
    except Exception:
        return simulate_detection()
