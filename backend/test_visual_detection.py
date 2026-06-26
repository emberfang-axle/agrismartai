"""Quick sanity checks for visual disease classification."""
import io

import numpy as np
from PIL import Image

from ai_model.visual_detection import classify_from_image


def _jpeg(img: Image.Image) -> bytes:
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()


def test_healthy():
    img = Image.new("RGB", (224, 224), (40, 160, 50))
    code, conf, _ = classify_from_image(_jpeg(img))
    assert code == "healthy", code
    assert conf >= 85


def test_blight_stripes():
    arr = np.zeros((224, 224, 3), dtype=np.uint8)
    arr[:, :] = [40, 150, 50]
    for y in range(0, 224, 30):
        arr[y : y + 8, :] = [220, 210, 60]
    code, conf, _ = classify_from_image(_jpeg(Image.fromarray(arr)))
    assert code == "bacterial_leaf_blight", code
    assert conf >= 85


def test_blast_spots():
    arr = np.full((224, 224, 3), [45, 155, 55], dtype=np.uint8)
    for cy, cx in [(60, 80), (140, 120), (90, 170), (50, 150)]:
        arr[cy - 12 : cy + 12, cx - 10 : cx + 10] = [130, 75, 45]
    code, conf, _ = classify_from_image(_jpeg(Image.fromarray(arr)))
    assert code == "rice_blast", code
    assert conf >= 85


def test_tungro_orange():
    arr = np.full((224, 224, 3), [210, 165, 55], dtype=np.uint8)
    code, conf, _ = classify_from_image(_jpeg(Image.fromarray(arr)))
    assert code == "tungro", code
    assert conf >= 85


if __name__ == "__main__":
    test_healthy()
    test_blight_stripes()
    test_blast_spots()
    test_tungro_orange()
    print("All visual detection tests passed.")
