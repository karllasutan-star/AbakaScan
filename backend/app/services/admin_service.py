from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.security import hash_password
from app.models.classification import ClassificationRecord
from app.models.user import User


# ============================================================
# ADMIN SERVICE ERRORS
# ============================================================

class AdminEmailExistsError(ValueError):
    pass


# ============================================================
# ADMIN OVERVIEW
# ============================================================

def get_admin_overview(
    db: Session,
) -> dict[str, int]:
    total_users = db.scalar(
        select(func.count(User.user_id))
    ) or 0

    total_regular_users = db.scalar(
        select(func.count(User.user_id)).where(
            func.upper(User.role) == "USER"
        )
    ) or 0

    total_admins = db.scalar(
        select(func.count(User.user_id)).where(
            func.upper(User.role) == "ADMIN"
        )
    ) or 0

    total_classifications = db.scalar(
        select(
            func.count(
                ClassificationRecord.classification_id
            )
        )
    ) or 0

    return {
        "total_users": total_users,
        "total_regular_users": total_regular_users,
        "total_admins": total_admins,
        "total_classifications": total_classifications,
    }


# ============================================================
# GET ALL ACCOUNTS
# ============================================================

def get_all_users(
    db: Session,
) -> list[User]:
    statement = (
        select(User)
        .order_by(
            User.created_at.desc()
        )
    )

    users = db.scalars(
        statement
    ).all()

    return list(users)


# ============================================================
# CREATE ADMINISTRATOR
# ============================================================

def create_administrator(
    db: Session,
    full_name: str,
    email: str,
    password: str,
) -> User:
    normalized_email = (
        email.strip().lower()
    )

    existing_user = db.scalar(
        select(User).where(
            User.email == normalized_email
        )
    )

    if existing_user is not None:
        raise AdminEmailExistsError(
            "An account with that email already exists."
        )

    administrator = User(
        full_name=full_name.strip(),
        email=normalized_email,
        password_hash=hash_password(
            password
        ),
        role="ADMIN",
        stakeholder_role=None,
        custom_role=None,

        # Administrator accounts are created by an
        # authenticated administrator, so they do not
        # need the public registration OTP flow.
        is_email_verified=True,

        email_verification_otp_hash=None,
        email_verification_expires_at=None,
        email_verification_attempts=0,

        failed_login_attempts=0,
        locked_until=None,

        password_reset_otp_hash=None,
        password_reset_expires_at=None,
        password_reset_attempts=0,
    )

    db.add(
        administrator
    )

    try:
        db.commit()
        db.refresh(
            administrator
        )

    except Exception:
        db.rollback()
        raise

    return administrator


# ============================================================
# GET ALL CLASSIFICATIONS
# ============================================================

def get_all_classifications(
    db: Session,
) -> list[
    tuple[
        ClassificationRecord,
        User,
    ]
]:
    statement = (
        select(
            ClassificationRecord,
            User,
        )
        .join(
            User,
            ClassificationRecord.user_id
            == User.user_id,
        )
        .order_by(
            ClassificationRecord.created_at.desc()
        )
    )

    rows = db.execute(
        statement
    ).all()

    return [
        (record, user)
        for record, user in rows
    ]