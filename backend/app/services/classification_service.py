from sqlalchemy import select
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
) -> ClassificationRecord:
    record = ClassificationRecord(
        user_id=user_id,
        predicted_grade=predicted_grade,
        confidence=confidence,
        model_name=model_name,
        image_file_name=validated_image.file_name,
        image_mime_type=validated_image.mime_type,
        image_data=validated_image.image_bytes,
    )

    db.add(record)

    try:
        db.commit()
        db.refresh(record)

    except Exception:
        db.rollback()
        raise

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
            ClassificationRecord.created_at.desc()
        )
    )

    records = db.scalars(statement).all()

    return list(records)


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

    return db.scalar(statement)


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