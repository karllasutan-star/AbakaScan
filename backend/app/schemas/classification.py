from datetime import datetime
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field


GradeLabel = Literal["JK", "S-I", "S-S2"]
GradeScore = Annotated[float, Field(ge=0.0, le=1.0)]


# ============================================================
# CLASSIFICATION RESPONSE
# ============================================================

class ClassificationResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    classification_id: int

    analysis_number: int = Field(ge=1)

    predicted_grade: str

    confidence: float = Field(
        ge=0.0,
        le=1.0,
    )

    created_at: datetime

    image_url: str | None = None

    saved_to_history: bool = True

    model_name: str | None = None

    grade_scores: dict[GradeLabel, GradeScore] | None = Field(
        default=None,
        description=(
            "Model scores for JK, S-I, and S-S2, each from 0 to 1. "
            "These scores are not verified grading accuracy."
        ),
    )


# ============================================================
# CLASSIFICATION HISTORY RECORD
# ============================================================

class ClassificationRecordResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    classification_id: int

    analysis_number: int = Field(ge=1)

    predicted_grade: str

    confidence: float = Field(
        ge=0.0,
        le=1.0,
    )

    created_at: datetime

    image_url: str | None = None

    model_name: str | None = None

    grade_scores: dict[GradeLabel, GradeScore] | None = Field(
        default=None,
        description=(
            "Saved grade model scores, when available. "
            "Older records may have no saved distribution."
        ),
    )
