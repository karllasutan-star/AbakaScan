from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.classification import ClassificationRecord
from app.services.image_service import ValidatedImage


# ============================================================
# CREATE CLASSIFICATION
# ============================================================

def create_classification_record(
    db: Session,
    user_id: int,
    predicted_grade: str,
    confidence: float,
    validated_image: ValidatedImage,
    model_name: str | None = None,
    grade_scores: dict[str, float] | None = None,
) -> ClassificationRecord:
    record_data = {
        "user_id": user_id,
        "predicted_grade": predicted_grade,
        "confidence": confidence,
        "model_name": model_name,
        "image_file_name": validated_image.file_name,
        "image_mime_type": validated_image.mime_type,
        "image_data": validated_image.image_bytes,
    }

    if grade_scores is not None:
        # Copy the original scores without converting or rounding them.
        record_data["grade_scores"] = dict(grade_scores)

    record = ClassificationRecord(**record_data)

    db.add(record)

    try:
        db.commit()
        db.refresh(record)

    except Exception:
        db.rollback()
        raise

    record.analysis_number = get_analysis_number(db, user_id, record.classification_id)
    return record


# ============================================================
# GET USER CLASSIFICATION HISTORY
# ============================================================

def get_user_classifications(
    db: Session,
    user_id: int,
) -> list[ClassificationRecord]:
    statement = (
        select(ClassificationRecord)
        .where(
            ClassificationRecord.user_id == user_id
        )
        .order_by(
            ClassificationRecord.created_at.desc(),
            ClassificationRecord.classification_id.desc()
        )
    )

    records = db.scalars(statement).all()

    # Number the complete account history before any UI filtering or sorting.
    records = list(records)
    for number, record in enumerate(
        sorted(records, key=lambda item: item.classification_id), start=1
    ):
        record.analysis_number = number
    return records


# ============================================================
# GET ONE USER CLASSIFICATION
# ============================================================

def get_user_classification(
    db: Session,
    user_id: int,
    classification_id: int,
) -> ClassificationRecord | None:
    statement = (
        select(ClassificationRecord)
        .where(
            ClassificationRecord.classification_id
            == classification_id,
            ClassificationRecord.user_id
            == user_id,
        )
    )

    record = db.scalar(statement)
    if record is not None:
        record.analysis_number = get_analysis_number(db, user_id, classification_id)
    return record


# ============================================================
# DELETE CLASSIFICATION
# ============================================================

def delete_classification_record(
    db: Session,
    record: ClassificationRecord,
) -> None:
    db.delete(record)

    try:
        db.commit()

    except Exception:
        db.rollback()
        raise


def get_analysis_number(
    db: Session,
    user_id: int,
    classification_id: int,
) -> int:
    """Display position in this account's current saved history, ordered by ID.

    This does not change any primary key or database sequence. Deleted records
    are omitted, so remaining display numbers close the gap after a refresh.
    """
    statement = select(func.count()).select_from(ClassificationRecord).where(
        ClassificationRecord.user_id == user_id,
        ClassificationRecord.classification_id <= classification_id,
    )
    return int(db.scalar(statement) or 0)
