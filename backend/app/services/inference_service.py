"""Experimental V2 abaca recognition followed by JK/S-I/S-S2 prediction.

These ResNet18 checkpoints were trained using the 26 development images.
Results on those images are training diagnostics, not independent accuracy.
Image-level recognition does not count bundles or prove material identity.
After recognition passes, return all three scores and the highest-scoring grade.
Confidence is the grade classifier score, not the material-recognition score.
Predictions are not certified grades. Generalization to new bundles is unverified.
Existing classification routes may save successful predictions to history.
"""

from dataclasses import dataclass
from hashlib import sha256
from math import isfinite
from pathlib import Path
from threading import Lock

import torch
from PIL import Image, ImageOps
from torchvision import transforms
from torchvision.models import resnet18


# For backend/app/services/inference_service.py, this is backend/app/ml/models.
MODEL_DIR = Path(__file__).resolve().parents[1] / "ml" / "models"
MATERIAL_PATH = MODEL_DIR / "material_gate_old_finetuned_v3.pt"
CLASSIFIER_PATH = MODEL_DIR / "grade_classifier_old_finetuned_v3.pt"
MODEL_NAME = "abakascan-resnet18-v3"
MATERIAL_CLASSES = ["non_abaca", "abaca"]
CLASSIFIER_CLASSES = ["JK", "S-I", "S-S2"]
MATERIAL_SHA256 = (
    "e7809497870c0612e0738ebe9045e883c15b396392d1103b6c11e9731c23c977"
)
CLASSIFIER_SHA256 = (
    "817754fc53c44fa928404f3a2176b5be01bd01bc49086ca8930059493b9ff569"
)
MEAN = [0.485, 0.456, 0.406]
STD = [0.229, 0.224, 0.225]
MATERIAL_ACCEPT_THRESHOLD = 0.80


@dataclass(frozen=True)
class PredictionResult:
    predicted_grade: str
    confidence: float
    model_name: str
    grade_scores: dict[str, float]


class ModelNotReadyError(RuntimeError):
    pass


class BundleDetectionError(ValueError):
    """Retain the existing route's exception interface for unsaved outcomes."""

    def __init__(self, message: str, code: str = "unidentified_object"):
        super().__init__(message)
        self.code = code


_models = None
_model_lock = Lock()
_prediction_lock = Lock()


def _file_sha256(path):
    digest = sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _load_classifier(path, expected_sha256, classes, material=False):
    if not path.is_file():
        raise ValueError(f"Model file was not found: {path.name}")
    if _file_sha256(path) != expected_sha256:
        raise ValueError(f"Model checksum mismatch: {path.name}")
    saved = torch.load(path, map_location="cpu", weights_only=True)
    if (
        saved.get("architecture") != "resnet18"
        or saved.get("classes") != classes
    ):
        raise ValueError(f"Unexpected architecture or classes: {path.name}")
    if (
        saved.get("input_size") != 224
        or saved.get("mean") != MEAN
        or saved.get("std") != STD
    ):
        raise ValueError(f"Unexpected preprocessing: {path.name}")
    if material and (
        saved.get("task") != "binary_material_recognition"
        or saved.get("accept_threshold") != MATERIAL_ACCEPT_THRESHOLD
    ):
        raise ValueError("Unexpected material-recognition task or threshold.")
    candidate = resnet18(weights=None)
    candidate.fc = torch.nn.Linear(candidate.fc.in_features, len(classes))
    candidate.load_state_dict(saved["state_dict"], strict=True)
    candidate.to("cpu").eval()
    return candidate


def _get_models():
    global _models
    with _model_lock:
        if _models is None:
            try:
                material = _load_classifier(
                    MATERIAL_PATH, MATERIAL_SHA256, MATERIAL_CLASSES, material=True
                )
                classifier = _load_classifier(
                    CLASSIFIER_PATH, CLASSIFIER_SHA256, CLASSIFIER_CLASSES
                )
                _models = (material, classifier)
            except Exception as error:
                raise ModelNotReadyError(
                    "Unable to load the ABAKASCAN V2 development recognition "
                    "and grade models. Check the model files and backend dependencies."
                ) from error
        return _models


def _prepare_full_image(image):
    width, height = image.size
    side = max(width, height)
    padded = ImageOps.expand(
        image,
        border=(
            (side - width) // 2,
            (side - height) // 2,
            (side - width + 1) // 2,
            (side - height + 1) // 2,
        ),
        fill=(124, 116, 104),
    )
    resized = transforms.functional.resize(
        padded,
        [224, 224],
        interpolation=transforms.InterpolationMode.BILINEAR,
        antialias=True,
    )
    tensor = transforms.functional.to_tensor(resized)
    return transforms.functional.normalize(tensor, MEAN, STD).unsqueeze(0)


def _validate_scores(scores, expected_count):
    values = [float(value) for value in scores]
    if (
        len(values) != expected_count
        or not all(isfinite(value) and 0 <= value <= 1 for value in values)
        or abs(sum(values) - 1.0) > 0.0001
    ):
        raise RuntimeError("The model returned invalid class scores.")
    return values


def _require_material(scores):
    values = _validate_scores(scores, len(MATERIAL_CLASSES))
    if values[MATERIAL_CLASSES.index("abaca")] < MATERIAL_ACCEPT_THRESHOLD:
        raise BundleDetectionError(
            "Material not identified with sufficient confidence. "
            "Please upload a clear image of one abaca bundle.",
            code="unidentified_object",
        )


def _select_grade(scores):
    values = _validate_scores(scores, len(CLASSIFIER_CLASSES))
    winner = max(range(len(values)), key=values.__getitem__)
    return CLASSIFIER_CLASSES[winner], values[winner]


def predict_abaca_grade(image: Image.Image) -> PredictionResult:
    if image.width <= 0 or image.height <= 0:
        raise ValueError("The image has invalid dimensions.")
    material, classifier = _get_models()
    try:
        rgb = ImageOps.exif_transpose(image).convert("RGB")
        tensor = _prepare_full_image(rgb)
        with _prediction_lock, torch.inference_mode():
            material_scores = material(tensor).softmax(dim=1)[0].cpu().tolist()
            _require_material(material_scores)
            scores = classifier(tensor).softmax(dim=1)[0].cpu().tolist()
            grade, confidence = _select_grade(scores)
            grade_scores = {
                label: float(score)
                for label, score in zip(CLASSIFIER_CLASSES, scores)
            }
    except BundleDetectionError:
        raise
    except Exception as error:
        raise RuntimeError("ABAKASCAN image analysis failed.") from error
    return PredictionResult(
        predicted_grade=grade,
        confidence=confidence,
        model_name=MODEL_NAME,
        grade_scores=grade_scores,
    )
