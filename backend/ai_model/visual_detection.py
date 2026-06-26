"""
AgriSmartAI :: Visual disease classification (no trained weights required).

Analyzes leaf color (RGB + HSV), lesions, stripes, and edge patterns so
predictions follow image content. Used when MobileNetV2 weights are not trained.
"""

from __future__ import annotations

import io
from typing import Dict, Tuple

import numpy as np
from PIL import Image

DISEASE_CLASSES = [
    "bacterial_leaf_blight",
    "rice_blast",
    "tungro",
    "healthy",
]


def _rgb_to_hsv_masks(rgb: np.ndarray) -> Dict[str, np.ndarray]:
    """HSV masks — more stable under field lighting than RGB alone."""
    hsv = np.array(Image.fromarray(rgb).convert("HSV"), dtype=np.uint8)
    h = hsv[:, :, 0].astype(np.float32)  # 0–255 maps to 0–360°
    s = hsv[:, :, 1].astype(np.float32)
    v = hsv[:, :, 2].astype(np.float32)

    hue_deg = h * 360.0 / 255.0
    green = (hue_deg >= 55) & (hue_deg <= 145) & (s > 28) & (v > 28)
    yellow = (hue_deg >= 18) & (hue_deg <= 58) & (s > 35) & (v > 40)
    orange = (hue_deg >= 5) & (hue_deg <= 28) & (s > 45) & (v > 35)
    brown = (hue_deg >= 5) & (hue_deg <= 35) & (s > 25) & (v > 20) & (v < 160)
    gray = (s < 35) & (v > 35) & (v < 185)

    return {
        "green": green,
        "yellow": yellow,
        "orange": orange,
        "brown": brown,
        "gray": gray,
        "lesion": brown | gray,
    }


def _color_masks(rgb: np.ndarray) -> Dict[str, np.ndarray]:
    r = rgb[:, :, 0].astype(np.float32)
    g = rgb[:, :, 1].astype(np.float32)
    b = rgb[:, :, 2].astype(np.float32)

    rgb_green = (g > r + 8) & (g > b + 8) & (g > 45)
    rgb_yellow = (r > 95) & (g > 95) & (b < 130) & ((r + g) > (b + 80))
    rgb_orange = (r > 140) & (g > 90) & (g < 185) & (b < 110) & (r > g)
    rgb_brown = (r > 65) & (g < 120) & (b < 95) & (r > g) & (r - g < 95)
    rgb_gray = (np.abs(r - g) < 32) & (np.abs(g - b) < 32) & (r < 170) & (r > 50)

    hsv = _rgb_to_hsv_masks(rgb)

    # Union RGB + HSV cues for robustness in sunlight/shade.
    green = rgb_green | hsv["green"]
    yellow = rgb_yellow | hsv["yellow"]
    orange = rgb_orange | hsv["orange"]
    brown = rgb_brown | hsv["brown"]
    gray = rgb_gray | hsv["gray"]
    lesion = brown | gray

    return {
        "green": green,
        "yellow": yellow,
        "orange": orange,
        "brown": brown,
        "gray": gray,
        "lesion": lesion,
    }


def _stripe_score(yellow: np.ndarray, green: np.ndarray) -> float:
    """Horizontal yellow stripes typical of bacterial leaf blight."""
    h, w = yellow.shape
    if h < 8 or w < 8:
        return 0.0

    row_yellow = yellow.mean(axis=1)
    row_green = green.mean(axis=1)
    active = row_green > 0.08
    if active.sum() < 4:
        return 0.0

    active_yellow = row_yellow[active]
    centered = active_yellow - active_yellow.mean()
    variance = float(np.var(centered))
    peak_ratio = float(active_yellow.max() / max(active_yellow.mean(), 1e-6))

    # Autocorrelation at ~stripe period detects repeating bands.
    if len(active_yellow) >= 12:
        ac = np.correlate(centered, centered, mode="full")
        mid = len(ac) // 2
        tail = ac[mid + 2 : mid + min(40, len(ac) - mid)]
        ac_peak = float(tail.max() / max(ac[mid], 1e-6)) if tail.size else 0.0
    else:
        ac_peak = 0.0

    return min(1.0, variance * 16.0 + max(0.0, peak_ratio - 1.15) * 0.4 + ac_peak * 0.25)


def _dilate(mask: np.ndarray, radius: int = 2) -> np.ndarray:
    out = mask.copy()
    h, w = mask.shape
    for y in range(h):
        for x in range(w):
            if mask[y, x]:
                y0, y1 = max(0, y - radius), min(h, y + radius + 1)
                x0, x1 = max(0, x - radius), min(w, x + radius + 1)
                out[y0:y1, x0:x1] = True
    return out


def _edge_density(rgb: np.ndarray, mask: np.ndarray | None = None) -> float:
    """Sobel-like edge density — blast lesions show sharp gray/brown borders."""
    gray = (
        0.299 * rgb[:, :, 0] + 0.587 * rgb[:, :, 1] + 0.114 * rgb[:, :, 2]
    ).astype(np.float32)
    gx = np.abs(np.diff(gray, axis=1, prepend=gray[:, :1]))
    gy = np.abs(np.diff(gray, axis=0, prepend=gray[:1, :]))
    edges = (gx + gy) > 28
    if mask is not None:
        region = _dilate(mask, radius=3)
        if region.sum() < 8:
            return 0.0
        return float(edges[region].mean())
    return float(edges.mean())


def _spot_score(lesion: np.ndarray, green: np.ndarray, rgb: np.ndarray) -> float:
    """Localized brown/gray lesions on green tissue (rice blast)."""
    h, w = lesion.shape
    if h < 8 or w < 8:
        return 0.0

    total = float(h * w)
    green_ratio = float(green.sum() / total)
    lesion_ratio = float(lesion.sum() / total)

    if green_ratio < 0.12 or lesion_ratio < 0.004:
        return lesion_ratio * 8.0

    dilated = _dilate(lesion, radius=2)
    near_green = dilated & green
    proximity = float(near_green.sum() / max(lesion.sum(), 1))
    edge_in_lesion = _edge_density(rgb, lesion)

    block = 12
    block_hits = []
    for y in range(0, h - block, block // 2):
        for x in range(0, w - block, block // 2):
            patch_green = green[y : y + block, x : x + block].mean()
            patch_lesion = lesion[y : y + block, x : x + block].mean()
            if patch_green > 0.20 and patch_lesion > 0.03:
                block_hits.append(patch_lesion)

    cluster_bonus = min(1.0, len(block_hits) * 0.15)
    max_block = max(block_hits) if block_hits else float(lesion.max())

    score = lesion_ratio * 10.0 + cluster_bonus + max_block * 2.5 + edge_in_lesion * 1.8
    if proximity > 0.5 and len(block_hits) >= 2:
        score += 0.6
    return min(1.0, score)


def _uniformity_score(green: np.ndarray) -> float:
    """Healthy leaves tend to have uniform green tone."""
    h, w = green.shape
    if h < 16 or w < 16:
        return 0.0
    block = 16
    means = []
    for y in range(0, h - block, block):
        for x in range(0, w - block, block):
            patch = green[y : y + block, x : x + block].mean()
            if patch > 0.25:
                means.append(patch)
    if len(means) < 4:
        return 0.0
    return float(1.0 - min(1.0, np.std(means) * 4.0))


def _softmax(scores: Dict[str, float]) -> Dict[str, float]:
    keys = list(scores.keys())
    vals = np.array([scores[k] for k in keys], dtype=np.float64)
    vals = vals - vals.max()
    exp = np.exp(vals)
    total = exp.sum() or 1.0
    return {k: float(v) for k, v in zip(keys, exp / total)}


def _display_confidence(probs: Dict[str, float], predicted: str) -> float:
    """
    Confidence reflects how clearly the image matches one disease class.
    Ambiguous images get lower scores instead of always showing 85%+.
    """
    raw = probs[predicted]
    sorted_vals = sorted(probs.values(), reverse=True)
    margin = sorted_vals[0] - sorted_vals[1] if len(sorted_vals) > 1 else sorted_vals[0]
    base = raw * 100.0

    if margin < 0.06:
        return round(min(base, 38.0 + margin * 350.0), 2)
    if margin < 0.15:
        return round(min(base, 52.0 + margin * 220.0), 2)
    if margin >= 0.40 and raw >= 0.50:
        return round(min(98.5, max(85.0, 80.0 + raw * 18.0)), 2)
    return round(min(98.5, max(55.0, base)), 2)


def classify_from_image(image_bytes: bytes) -> Tuple[str, float, Dict[str, float]]:
    """
    Return (disease_code, confidence_percent, class_probabilities).
    """
    if not image_bytes:
        probs = {c: 0.25 for c in DISEASE_CLASSES}
        return "healthy", 0.0, probs

    try:
        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception:
        probs = {c: 0.25 for c in DISEASE_CLASSES}
        return "healthy", 0.0, probs

    rgb = np.array(img.resize((256, 256)), dtype=np.uint8)
    masks = _color_masks(rgb)
    total = float(rgb.shape[0] * rgb.shape[1])

    green_ratio = float(masks["green"].sum() / total)
    yellow_ratio = float(masks["yellow"].sum() / total)
    orange_ratio = float(masks["orange"].sum() / total)
    brown_ratio = float(masks["brown"].sum() / total)
    gray_ratio = float(masks["gray"].sum() / total)
    lesion_ratio = float(masks["lesion"].sum() / total)

    stripe = _stripe_score(masks["yellow"], masks["green"])
    spots = _spot_score(masks["lesion"], masks["green"], rgb)
    uniformity = _uniformity_score(masks["green"])

    scores = {
        "healthy": (
            0.35
            + green_ratio * 2.4
            + uniformity * 1.2
            - lesion_ratio * 2.0
            - yellow_ratio * 1.0
            - orange_ratio * 1.3
        ),
        "bacterial_leaf_blight": (
            0.12 + yellow_ratio * 2.6 + stripe * 2.0 + green_ratio * 0.35
        ),
        "rice_blast": (
            0.10 + spots * 2.4 + brown_ratio * 2.4 + gray_ratio * 1.5
        ),
        "tungro": (
            0.08 + orange_ratio * 3.0 + yellow_ratio * 1.4 - green_ratio * 0.7
        ),
    }

    if green_ratio > 0.45 and lesion_ratio < 0.025 and yellow_ratio < 0.07 and orange_ratio < 0.06:
        scores["healthy"] += 1.4
    if orange_ratio > 0.10 or (yellow_ratio > 0.16 and green_ratio < 0.28):
        scores["tungro"] += 1.1
    if stripe > 0.30 and yellow_ratio > 0.05 and green_ratio > 0.15:
        scores["bacterial_leaf_blight"] += 1.2
    if spots > 0.16 and green_ratio > 0.16:
        scores["rice_blast"] += 1.5
    if spots > 0.32:
        scores["rice_blast"] += 0.9

    probs = _softmax(scores)
    predicted = max(probs, key=probs.get)
    confidence = _display_confidence(probs, predicted)

    return predicted, confidence, probs
