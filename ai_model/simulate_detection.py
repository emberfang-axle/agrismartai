# AgriSmartAI — Simulated Disease Detection
# OBJECTIVE 2: Simulated detection for outline defense (replace with train.py for final defense)

import random
import json
import sys

DISEASES = [
    "Bacterial Leaf Blight",
    "Rice Blast",
    "Tungro",
    "Healthy",
]

FERTILIZER = {
    "Bacterial Leaf Blight": [
        "Reduce nitrogen fertilizer by 30% immediately",
        "Apply muriate of potash (MOP) at 40 kg/ha",
        "Drain flooded fields and consult DA for copper-based bactericide",
    ],
    "Rice Blast": [
        "Apply silicon-based fertilizer (calcium silicate) at 200 kg/ha",
        "Reduce nitrogen — use balanced NPK 14-14-14",
        "Spray tricyclazole fungicide per DA RFO XI recommendation",
    ],
    "Tungro": [
        "Apply balanced NPK with extra potassium",
        "Control green leafhoppers with recommended insecticide",
        "Replant with tungro-resistant variety (NSIC Rc 222)",
    ],
    "Healthy": [
        "Continue regular NPK schedule (14-14-14 at tillering)",
        "Apply zinc sulfate if leaves show yellowing",
        "Monitor weekly and maintain proper water level",
    ],
}


def simulate_detection():
    """OBJECTIVE 2: Returns random disease with 70-98% confidence."""
    disease = random.choice(DISEASES)
    confidence = round(random.uniform(0.70, 0.98), 4)
    return {
        "disease": disease,
        "confidence": confidence,
        "confidence_percent": f"{confidence * 100:.1f}%",
        "fertilizer_recommendations": FERTILIZER[disease],
        "da_message": (
            "Please consult the Department of Agriculture (DA) RFO XI "
            "in New Bataan, Davao de Oro for field verification and "
            "approved input recommendations."
        ),
        "severity": (
            "Severe" if confidence >= 0.88
            else "Moderate" if confidence >= 0.78
            else "Mild"
        ),
    }


if __name__ == "__main__":
    result = simulate_detection()
    print("=" * 50)
    print("AgriSmartAI — Simulated Detection Result")
    print("=" * 50)
    print(json.dumps(result, indent=2))
    print()
    print(f"Disease:     {result['disease']}")
    print(f"Confidence:  {result['confidence_percent']}")
    print(f"Severity:    {result['severity']}")
    print()
    print("Fertilizer Recommendations:")
    for i, step in enumerate(result["fertilizer_recommendations"], 1):
        print(f"  {i}. {step}")
    print()
    print(f"DA Message:  {result['da_message']}")
