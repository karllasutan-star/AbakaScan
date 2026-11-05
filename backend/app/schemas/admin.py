from datetime import datetime

from pydantic import (
    BaseModel,
    ConfigDict,
    EmailStr,
    Field,
    model_validator,
)


# ============================================================
# ADMIN OVERVIEW
# ============================================================

class AdminOverviewResponse(BaseModel):
    total_users: int
    total_regular_users: int
    total_admins: int
    total_classifications: int


# ============================================================
# ADMIN USER / ACCOUNT
# ============================================================

class AdminUserResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    user_id: int
    full_name: str
    email: str
    role: str

    stakeholder_role: str | None = None
    custom_role: str | None = None

    is_email_verified: bool

    created_at: datetime


# ============================================================
# CREATE ADMINISTRATOR
# ============================================================

class CreateAdminRequest(BaseModel):
    full_name: str = Field(
        min_length=2,
        max_length=150,
    )

    email: EmailStr

    password: str = Field(
        min_length=8,
        max_length=128,
    )

    @model_validator(mode="after")
    def normalize_values(self):
        self.full_name = self.full_name.strip()

        self.email = str(
            self.email
        ).strip().lower()

        return self


# ============================================================
# ADMIN CLASSIFICATION RECORD
# ============================================================

class AdminClassificationResponse(BaseModel):
    classification_id: int

    user_id: int

    owner_display_name: str

    user_email: str | None = None

    predicted_grade: str

    confidence: float = Field(
        ge=0.0,
        le=1.0,
    )

    created_at: datetime

    image_url: str | None = None

    model_name: str | None = None