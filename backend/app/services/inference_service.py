from dataclasses import dataclass
from pathlib import Path
from threading import Lock

from PIL import Image
from ultralytics import YOLO


MODEL_PATH = (
    Path(__file__).resolve().parents[1]
    / "ml"
    / "models"
    / "abakascan_classifier.pt"
)

MODEL_NAME = "yolo26n-cls-abakascan-prototype"

GRADE_NAMES = {
    "grade-jk": "JK",
    "grade-s-i": "S-I",
    "grade-s-s2": "S-S2",
}


@dataclass(frozen=True)
class PredictionResult:
    predicted_grade: str
    confidence: float
    model_name: str


class ModelNotReadyError(RuntimeError):
    pass


_model = None
_model_lock = Lock()


def _get_model():
    global _model

    if _model is not None:
        return _model

    with _model_lock:
        if _model is not None:
            return _model

        if not MODEL_PATH.exists():
            raise ModelNotReadyError(
                "ABAKASCAN model file was not found."
            )

        try:
            _model = YOLO(
                str(MODEL_PATH)
            )
        except Exception as error:
            raise ModelNotReadyError(
                "Unable to load the ABAKASCAN model."
            ) from error

    return _model


def predict_abaca_grade(
    image: Image.Image,
) -> PredictionResult:
    if image.width <= 0 or image.height <= 0:
        raise ValueError(
            "The image has invalid dimensions."
        )

    model = _get_model()

    try:
        results = model.predict(
            source=image,
            imgsz=224,
            device="cpu",
            verbose=False,
        )
    except Exception as error:
        raise RuntimeError(
            "ABAKASCAN model inference failed."
        ) from error

    if not results:
        raise RuntimeError(
            "The model returned no prediction."
        )

    result = results[0]

    if result.probs is None:
        raise RuntimeError(
            "The model returned no "
            "classification probabilities."
        )

    class_id = int(
        result.probs.top1
    )

    confidence = float(
        result.probs.top1conf
    )

    raw_class_name = str(
        result.names[class_id]
    )

    predicted_grade = GRADE_NAMES.get(
        raw_class_name,
        raw_class_name,
    )

    return PredictionResult(
        predicted_grade=predicted_grade,
        confidence=confidence,
        model_name=MODEL_NAME,
    )