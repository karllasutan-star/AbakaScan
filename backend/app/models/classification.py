from datetime import datetime

from sqlalchemy import (
    DateTime,
    Float,
    ForeignKey,
    Integer,
    LargeBinary,
    String,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database.database import Base


class ClassificationRecord(Base):
    __tablename__ = "classification_records"

    classification_id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        index=True,
    )

    user_id: Mapped[int] = mapped_column(
        ForeignKey(
            "users.user_id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    predicted_grade: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
    )

    confidence: Mapped[float] = mapped_column(
        Float,
        nullable=False,
    )

    model_name: Mapped[str | None] = mapped_column(
        String(150),
        nullable=True,
    )

    image_file_name: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    image_mime_type: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    image_data: Mapped[bytes | None] = mapped_column(
        LargeBinary,
        nullable=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )