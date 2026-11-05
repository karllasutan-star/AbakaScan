from fastapi import APIRouter, Depends

from app.core.auth import get_current_user
from app.models.user import User
from app.schemas.user import AuthenticatedUserResponse


router = APIRouter(
    tags=["Profile"],
)


@router.get(
    "/profile",
    response_model=AuthenticatedUserResponse,
)
def get_profile(
    current_user: User = Depends(get_current_user),
):
    return AuthenticatedUserResponse(
        user_id=current_user.user_id,
        full_name=current_user.full_name,
        email=current_user.email,
        role=current_user.role,
        stakeholder_role=current_user.stakeholder_role,
        custom_role=current_user.custom_role,
    )