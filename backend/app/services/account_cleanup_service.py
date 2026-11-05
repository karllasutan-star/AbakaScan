from datetime import datetime, timedelta, timezone

from sqlalchemy import delete
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.user import User


def cleanup_expired_unverified_accounts(
    db: Session,
) -> int:
    cutoff_time = (
        datetime.now(timezone.utc)
        - timedelta(
            hours=settings.unverified_account_retention_hours,
        )
    )

    result = db.execute(
        delete(User).where(
            User.role == "USER",
            User.is_email_verified.is_(False),
            User.created_at < cutoff_time,
        )
    )

    db.commit()

    return result.rowcount or 0