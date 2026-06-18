"""Rice-leaf validation — accepts healthy AND diseased rice (Tungro, BLB, Blast)."""

from dataclasses import dataclass
from io import BytesIO

from PIL import Image


@dataclass
class ValidationResult:
    is_valid: bool
    message: str
    green_ratio: float = 0.0  # foliage ratio (kept name for API compat)
    score: float = 0.0


def _is_rice_foliage(r: int, g: int, b: int) -> bool:
  """Detect rice leaf pixels: green, yellow (Tungro), or brown disease spots."""
  # Healthy / light green leaf
  if g >= 40 and g >= r - 8 and g >= b - 8 and (g - min(r, b)) >= 4:
    if r < 200 and b < 200:
      return True

  # Tungro / chlorosis — yellow, yellow-orange, pale yellow leaves (low blue)
  if r >= 65 and g >= 55 and b <= max(r, g) + 15:
    if (r + g) >= 130 and abs(r - g) < 90 and b < r + 45:
      if (g - b) > 35 and not (r > 180 and g < 70):
        return True

  # Orange-yellow tungro tips
  if r >= 80 and g >= 50 and b <= 80:
    if r >= g - 30 and (r + g) >= 120:
      return True

  # Brown blast/blight lesions still on rice leaf
  if r >= 45 and g >= 28 and b <= 95:
    if r >= g - 15 and g >= b and (r + g) >= 75:
      return True

  # Yellow-green field rice (mixed lighting)
  if g >= 50 and r >= 45 and b <= 110:
    if g >= b + 5 and r >= b:
      return True

  return False


def _is_skin(r: int, g: int, b: int) -> bool:
  # Yellow/orange Tungro leaves look like skin in RGB — exclude foliage first.
  if _is_rice_foliage(r, g, b):
    return False
  # Real skin has more blue than chlorotic yellow leaves.
  return (
    r > 95
    and g > 40
    and b > 20
    and r > g + 12
    and (r - b) > 20
    and b > g - 55
  )


def _is_blue_sky(r: int, g: int, b: int) -> bool:
  return b > r + 22 and b > g + 12 and b > 95


def _is_non_plant(r: int, g: int, b: int) -> bool:
  # Bright red objects (toys, clothes)
  if r > 170 and g < 70 and b < 70:
    return True
  # Purple / pink flowers
  if r > 100 and b > 100 and g < 75:
    return True
  # Deep blue objects
  if b > 130 and b > r + 40 and b > g + 30:
    return True
  return False


def validate_rice_leaf(image_bytes: bytes) -> ValidationResult:
  try:
    img = Image.open(BytesIO(image_bytes)).convert("RGB")
  except Exception:
    return ValidationResult(False, "Invalid image file. Use JPG or PNG.")

  w, h = img.size
  if w < 80 or h < 80:
    return ValidationResult(False, "Image too small. Move closer to the rice leaf.")

  step = max(1, int((w * h / 6000) ** 0.5))

  foliage = 0
  skin = 0
  blue_dom = 0
  gray = 0
  non_plant = 0
  total = 0

  cx0, cy0 = int(w * 0.12), int(h * 0.12)
  cx1, cy1 = int(w * 0.88), int(h * 0.88)
  center_foliage = 0
  center_total = 0

  for y in range(0, h, step):
    for x in range(0, w, step):
      r, g, b = img.getpixel((x, y))
      total += 1
      in_center = cx0 <= x <= cx1 and cy0 <= y <= cy1
      if in_center:
        center_total += 1

      mx = max(r, g, b)
      mn = min(r, g, b)
      saturation = (mx - mn) / mx if mx > 0 else 0

      if _is_rice_foliage(r, g, b):
        foliage += 1
        if in_center:
          center_foliage += 1
      if _is_skin(r, g, b):
        skin += 1
      if _is_blue_sky(r, g, b):
        blue_dom += 1
      if saturation < 0.10 and mx < 180:
        gray += 1
      if _is_non_plant(r, g, b):
        non_plant += 1

  if total == 0:
    return ValidationResult(False, "Could not analyze image.")

  foliage_ratio = foliage / total
  center_ratio = center_foliage / center_total if center_total else 0
  skin_ratio = skin / total
  blue_ratio = blue_dom / total
  gray_ratio = gray / total
  non_plant_ratio = non_plant / total

  aspect = w / h
  if aspect < 0.3 or aspect > 3.0:
    return ValidationResult(
      False,
      "❌ Please frame one rice leaf in the photo.",
      foliage_ratio,
    )

  if skin_ratio > 0.14:
    return ValidationResult(
      False,
      "❌ Not rice. Photograph only the leaf — no faces or hands.",
      foliage_ratio,
    )

  if blue_ratio > 0.25:
    return ValidationResult(
      False,
      "❌ Not rice. Avoid sky/water — focus on the rice leaf only.",
      foliage_ratio,
    )

  if non_plant_ratio > 0.35:
    return ValidationResult(
      False,
      "❌ Not a rice leaf. Other colored objects detected.",
      foliage_ratio,
    )

  if gray_ratio > 0.55 and foliage_ratio < 0.08:
    return ValidationResult(
      False,
      "❌ Image too dark. Use a clear photo of the rice leaf.",
      foliage_ratio,
    )

  # Accept diseased rice (Tungro yellow) — lower foliage threshold
  if foliage_ratio < 0.10:
    return ValidationResult(
      False,
      "❌ Not a rice leaf. Show a rice leaf only (green, yellow, or diseased).",
      foliage_ratio,
    )

  if center_ratio < 0.08:
    return ValidationResult(
      False,
      "❌ Center the rice leaf in the frame.",
      foliage_ratio,
    )

  score = min(1.0, foliage_ratio * 1.8 + center_ratio * 0.6 - skin_ratio - blue_ratio * 0.4)
  return ValidationResult(
    True,
    "✅ Rice leaf detected! Analyzing...",
    foliage_ratio,
    score,
  )
