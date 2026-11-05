from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.auth import get_current_user
from app.database.database import get_db
from app.models.user import User
from app.schemas.admin import (
    AdminClassificationResponse,
    AdminOverviewResponse,
    AdminUserResponse,
    CreateAdminRequest,
)
from app.services.admin_service import (
    AdminEmailExistsError,
    create_administrator,
    get_admin_overview,
    get_all_classifications,
    get_all_users,
)


router = APIRouter(
    prefix="/admin",
    tags=["Administrator"],
)


# ============================================================
# ADMIN AUTHORIZATION
# ============================================================

def require_admin(
    current_user: User,
) -> None:
    if current_user.role.upper() != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Administrator access is required.",
        )


# ============================================================
# USER RESPONSE BUILDER
# ============================================================

def build_user_response(
    user: User,
) -> AdminUserResponse:
    return AdminUserResponse(
        user_id=user.user_id,
        full_name=user.full_name,
        email=user.email,
        role=user.role,
        stakeholder_role=user.stakeholder_role,
        custom_role=user.custom_role,
        is_email_verified=user.is_email_verified,
        created_at=user.created_at,
    )


# ============================================================
# ADMIN OVERVIEW
# ============================================================

@router.get(
    "/overview",
    response_model=AdminOverviewResponse,
)
def admin_overview(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(
        current_user,
    )

    overview = get_admin_overview(
        db=db,
    )

    return AdminOverviewResponse(
        **overview
    )


# ============================================================
# GET ALL USERS
# ============================================================

@router.get(
    "/users",
    response_model=list[AdminUserResponse],
)
def admin_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(
        current_user,
    )

    users = get_all_users(
        db=db,
    )

    return [
        build_user_response(user)
        for user in users
    ]


# ============================================================
# CREATE ADMINISTRATOR
# ============================================================

@router.post(
    "/admins",
    response_model=AdminUserResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_admin_account(
    data: CreateAdminRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(
        current_user,
    )

    try:
        administrator = create_administrator(
            db=db,
            full_name=data.full_name,
            email=str(data.email),
            password=data.password,
        )

    except AdminEmailExistsError as error:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(error),
        ) from error

    except IntegrityError as error:
        db.rollback()

        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "An account with that email "
                "already exists."
            ),
        ) from error

    except Exception as error:
        db.rollback()

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=(
                "Unable to create the "
                "administrator account."
            ),
        ) from error

    return build_user_response(
        administrator,
    )


# ============================================================
# GET ALL CLASSIFICATIONS
# ============================================================

@router.get(
    "/classifications",
    response_model=list[AdminClassificationResponse],
)
def admin_classifications(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_admin(
        current_user,
    )

    rows = get_all_classifications(
        db=db,
    )

    return [
        AdminClassificationResponse(
            classification_id=record.classification_id,
            user_id=user.user_id,
            owner_display_name=(
                user.full_name
                if user.full_name.strip()
                else user.email
            ),
            user_email=user.email,
            predicted_grade=record.predicted_grade,
            confidence=record.confidence,
            created_at=record.created_at,
            image_url=(
                f"/classifications/"
                f"{record.classification_id}/image"
            ),
            model_name=record.model_name,
        )
        for record, user in rows
    ]