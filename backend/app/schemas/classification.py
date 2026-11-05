from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


# ============================================================
# CLASSIFICATION RESPONSE
# ============================================================

class ClassificationResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    classification_id: int

    predicted_grade: str

    confidence: float = Field(
        ge=0.0,
        le=1.0,
    )

    created_at: datetime

    image_url: str | None = None

    saved_to_history: bool = True

    model_name: str | None = None


# ============================================================
# CLASSIFICATION HISTORY RECORD
# ============================================================

class ClassificationRecordResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    classification_id: int

    predicted_grade: str

    confidence: float = Field(
        ge=0.0,
        le=1.0,
    )

    created_at: datetime

    image_url: str | None = None

    model_name: str | None = None