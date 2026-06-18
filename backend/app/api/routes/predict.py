from fastapi import APIRouter, File, HTTPException, UploadFile

from app.services.detection_service import DetectionService

router = APIRouter(tags=["detection"])
_detection = DetectionService()


@router.post("/validate")
async def validate(file: UploadFile = File(...)):
    """Check if image is a rice leaf before running disease detection."""
    contents = await _read_image(file)
    return _detection.validate(contents)


@router.post("/predict")
async def predict(file: UploadFile = File(...)):
    contents = await _read_image(file)
    return _detection.predict(contents)


async def _read_image(file: UploadFile) -> bytes:
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(400, "File must be an image (JPG/PNG)")

    contents = await file.read()
    if len(contents) > 10 * 1024 * 1024:
        raise HTTPException(400, "Image too large (max 10 MB)")
    if len(contents) < 100:
        raise HTTPException(400, "Empty or invalid image")
    return contents


@router.get("/simulate")
async def simulate():
    return _detection.simulate()
