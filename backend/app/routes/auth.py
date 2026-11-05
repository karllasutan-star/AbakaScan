from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session
from datetime import datetime, timedelta, timezone
import math
MAX_LOGIN_ATTEMPTS = 5
LOCKOUT_SECONDS = 60

from app.core.config import settings
from app.core.security import (
    create_access_token,
    generate_email_verification_otp,
    generate_password_reset_otp,
    hash_email_verification_otp,
    hash_password,
    hash_password_reset_otp,
    verify_email_verification_otp,
    verify_password,
    verify_password_reset_otp,
)
from app.database.database import get_db
from app.models.user import User
from app.services.email_service import (
    send_password_reset_email,
    send_verification_email,
)


from app.schemas.user import (
    AuthenticatedUserResponse,
    EmailVerificationResponse,
    RegistrationPendingResponse,
    ResendVerificationRequest,
    UserLoginRequest,
    UserLoginResponse,
    UserRegisterRequest,
    VerifyEmailRequest,
    ForgotPasswordRequest,
    PasswordResetResponse,
    ResetPasswordRequest,
)


router = APIRouter(
    tags=["Authentication"],
)


# ============================================================
# REGISTER
# ============================================================

@router.post(
    "/register",
    response_model=RegistrationPendingResponse,
    status_code=status.HTTP_201_CREATED,
)
def register_user(
    request: UserRegisterRequest,
    db: Session = Depends(get_db),
):
    email = str(request.email).lower().strip()

    existing_user = db.scalar(
        select(User).where(User.email == email)
    )

    if existing_user is not None:
        if existing_user.is_email_verified:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="An account with that email already exists.",
            )

        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "An account with that email already exists "
                "but has not been verified. "
                "Please resend the verification code."
            ),
        )

    otp = generate_email_verification_otp()

    otp_hash = hash_email_verification_otp(
        otp,
    )

    expires_at = (
        datetime.now(timezone.utc)
        + timedelta(
            minutes=settings.email_verification_otp_minutes,
        )
    )

    hashed_password = hash_password(
        request.password,
    )

    user = User(
        full_name=request.full_name.strip(),
        email=email,
        password_hash=hashed_password,
        role="USER",
        stakeholder_role=request.stakeholder_role,
        custom_role=request.custom_role,
        is_email_verified=False,
        email_verification_otp_hash=otp_hash,
        email_verification_expires_at=expires_at,
        email_verification_attempts=0,
    )

    db.add(user)

    try:
        db.commit()
        db.refresh(user)
    except Exception:
        db.rollback()

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to create account.",
        )

    try:
        send_verification_email(
            recipient_email=user.email,
            otp=otp,
        )
    except RuntimeError:
        user.email_verification_otp_hash = None
        user.email_verification_expires_at = None
        user.email_verification_attempts = 0

        db.commit()

        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "Account was created, but the verification "
                "email could not be sent. "
                "Please request a new verification code."
            ),
        )

    return RegistrationPendingResponse(
        message=(
            "Registration successful. "
            "A verification code was sent to your email."
        ),
        email=user.email,
        verification_required=True,
    )

@router.post(
    "/verify-email",
    response_model=EmailVerificationResponse,
    status_code=status.HTTP_200_OK,
)
def verify_email(
    request: VerifyEmailRequest,
    db: Session = Depends(get_db),
):
    email = str(request.email).lower().strip()

    user = db.scalar(
        select(User).where(User.email == email)
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found.",
        )

    if user.is_email_verified:
        return EmailVerificationResponse(
            message="Email is already verified.",
            email=user.email,
            verified=True,
        )

    if (
        user.email_verification_otp_hash is None
        or user.email_verification_expires_at is None
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "There is no active verification code. "
                "Please request a new code."
            ),
        )

    now = datetime.now(timezone.utc)

    expires_at = user.email_verification_expires_at

    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(
            tzinfo=timezone.utc,
        )

    if expires_at <= now:
        user.email_verification_otp_hash = None
        user.email_verification_expires_at = None
        user.email_verification_attempts = 0

        db.commit()

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Verification code has expired. "
                "Please request a new code."
            ),
        )

    is_valid = verify_email_verification_otp(
        request.otp,
        user.email_verification_otp_hash,
    )

    if not is_valid:
        user.email_verification_attempts = (
            user.email_verification_attempts or 0
        ) + 1

        attempts_remaining = (
            settings.email_verification_max_attempts
            - user.email_verification_attempts
        )

        if attempts_remaining <= 0:
            user.email_verification_otp_hash = None
            user.email_verification_expires_at = None
            user.email_verification_attempts = 0

            db.commit()

            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=(
                    "Too many incorrect verification attempts. "
                    "Please request a new code."
                ),
            )

        db.commit()

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Incorrect verification code. "
                f"{attempts_remaining} "
                f"{'attempt' if attempts_remaining == 1 else 'attempts'} "
                "remaining."
            ),
        )

    user.is_email_verified = True
    user.email_verification_otp_hash = None
    user.email_verification_expires_at = None
    user.email_verification_attempts = 0

    db.commit()
    db.refresh(user)

    return EmailVerificationResponse(
        message=(
            "Email verified successfully. "
            "You can now log in."
        ),
        email=user.email,
        verified=True,
    )

@router.post(
    "/resend-verification",
    response_model=EmailVerificationResponse,
    status_code=status.HTTP_200_OK,
)
def resend_verification(
    request: ResendVerificationRequest,
    db: Session = Depends(get_db),
):
    email = str(request.email).lower().strip()

    user = db.scalar(
        select(User).where(User.email == email)
    )

    if user is None:
        return EmailVerificationResponse(
            message=(
                "If an unverified account exists for this "
                "email, a verification code will be sent."
            ),
            email=email,
            verified=False,
        )

    if user.is_email_verified:
        return EmailVerificationResponse(
            message="Email is already verified.",
            email=user.email,
            verified=True,
        )

    now = datetime.now(timezone.utc)

    if user.email_verification_expires_at is not None:
        expires_at = user.email_verification_expires_at

        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(
                tzinfo=timezone.utc,
            )

        original_sent_at = (
            expires_at
            - timedelta(
                minutes=settings.email_verification_otp_minutes,
            )
        )

        resend_available_at = (
            original_sent_at
            + timedelta(seconds=60)
        )

        if resend_available_at > now:
            remaining_seconds = max(
                1,
                math.ceil(
                    (
                        resend_available_at - now
                    ).total_seconds()
                ),
            )

            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=(
                    "Please wait "
                    f"{remaining_seconds} seconds "
                    "before requesting another code."
                ),
            )

    otp = generate_email_verification_otp()

    user.email_verification_otp_hash = (
        hash_email_verification_otp(
            otp,
        )
    )

    user.email_verification_expires_at = (
        now
        + timedelta(
            minutes=settings.email_verification_otp_minutes,
        )
    )

    user.email_verification_attempts = 0

    db.commit()
    db.refresh(user)

    try:
        send_verification_email(
            recipient_email=user.email,
            otp=otp,
        )
    except RuntimeError:
        user.email_verification_otp_hash = None
        user.email_verification_expires_at = None
        user.email_verification_attempts = 0

        db.commit()

        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "Unable to send verification email. "
                "Please try again."
            ),
        )

    return EmailVerificationResponse(
        message=(
            "A new verification code was sent "
            "to your email."
        ),
        email=user.email,
        verified=False,
    )


@router.post(
    "/forgot-password",
    response_model=PasswordResetResponse,
    status_code=status.HTTP_200_OK,
)
def forgot_password(
    request: ForgotPasswordRequest,
    db: Session = Depends(get_db),
):
    email = str(request.email).lower().strip()

    user = db.scalar(
        select(User).where(User.email == email)
    )

    generic_message = (
        "If a verified ABAKASCAN account exists for this "
        "email, a password reset code will be sent."
    )

    if user is None or not user.is_email_verified:
        return PasswordResetResponse(
            message=generic_message,
            email=email,
            reset=False,
        )

    now = datetime.now(timezone.utc)

    if user.password_reset_expires_at is not None:
        expires_at = user.password_reset_expires_at

        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(
                tzinfo=timezone.utc,
            )

        original_sent_at = (
            expires_at
            - timedelta(
                minutes=settings.password_reset_otp_minutes,
            )
        )

        resend_available_at = (
            original_sent_at
            + timedelta(seconds=60)
        )

        if resend_available_at > now:
            remaining_seconds = max(
                1,
                math.ceil(
                    (
                        resend_available_at - now
                    ).total_seconds()
                ),
            )

            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=(
                    "Please wait "
                    f"{remaining_seconds} seconds "
                    "before requesting another "
                    "password reset code."
                ),
            )

    otp = generate_password_reset_otp()

    user.password_reset_otp_hash = (
        hash_password_reset_otp(
            otp,
        )
    )

    user.password_reset_expires_at = (
        now
        + timedelta(
            minutes=settings.password_reset_otp_minutes,
        )
    )

    user.password_reset_attempts = 0

    db.commit()
    db.refresh(user)

    try:
        send_password_reset_email(
            recipient_email=user.email,
            otp=otp,
        )
    except RuntimeError:
        user.password_reset_otp_hash = None
        user.password_reset_expires_at = None
        user.password_reset_attempts = 0

        db.commit()

        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "Unable to send password reset email. "
                "Please try again."
            ),
        )

    return PasswordResetResponse(
        message=(
            "A password reset code was sent "
            "to your email."
        ),
        email=user.email,
        reset=False,
    )

@router.post(
    "/reset-password",
    response_model=PasswordResetResponse,
    status_code=status.HTTP_200_OK,
)
def reset_password(
    request: ResetPasswordRequest,
    db: Session = Depends(get_db),
):
    email = str(request.email).lower().strip()

    user = db.scalar(
        select(User).where(User.email == email)
    )

    if (
        user is None
        or not user.is_email_verified
        or user.password_reset_otp_hash is None
        or user.password_reset_expires_at is None
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Invalid or expired password reset code."
            ),
        )

    now = datetime.now(timezone.utc)

    expires_at = user.password_reset_expires_at

    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(
            tzinfo=timezone.utc,
        )

    if expires_at <= now:
        user.password_reset_otp_hash = None
        user.password_reset_expires_at = None
        user.password_reset_attempts = 0

        db.commit()

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Password reset code has expired. "
                "Please request a new code."
            ),
        )

    is_valid = verify_password_reset_otp(
        request.otp,
        user.password_reset_otp_hash,
    )

    if not is_valid:
        user.password_reset_attempts = (
            user.password_reset_attempts or 0
        ) + 1

        attempts_remaining = (
            settings.password_reset_max_attempts
            - user.password_reset_attempts
        )

        if attempts_remaining <= 0:
            user.password_reset_otp_hash = None
            user.password_reset_expires_at = None
            user.password_reset_attempts = 0

            db.commit()

            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=(
                    "Too many incorrect reset attempts. "
                    "Please request a new code."
                ),
            )

        db.commit()

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Incorrect password reset code. "
                f"{attempts_remaining} "
                f"{'attempt' if attempts_remaining == 1 else 'attempts'} "
                "remaining."
            ),
        )

    user.password_hash = hash_password(
        request.new_password,
    )

    user.password_reset_otp_hash = None
    user.password_reset_expires_at = None
    user.password_reset_attempts = 0

    user.failed_login_attempts = 0
    user.locked_until = None

    db.commit()
    db.refresh(user)

    return PasswordResetResponse(
        message=(
            "Password reset successfully. "
            "You can now log in with your new password."
        ),
        email=user.email,
        reset=True,
    )

# ============================================================
# LOGIN
# ============================================================

@router.post(
    "/login",
    response_model=UserLoginResponse,
    status_code=status.HTTP_200_OK,
)
def login_user(
    request: UserLoginRequest,
    db: Session = Depends(get_db),
):
    identifier = request.identifier.strip().lower()

    # Find account using email.
    user = db.scalar(
        select(User).where(User.email == identifier)
    )

    # Use the same message for an unknown email.
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )

    now = datetime.now(timezone.utc)

    # --------------------------------------------------------
    # CHECK WHETHER ACCOUNT IS CURRENTLY LOCKED
    # --------------------------------------------------------

    if user.locked_until is not None:
        locked_until = user.locked_until

        if locked_until.tzinfo is None:
            locked_until = locked_until.replace(
                tzinfo=timezone.utc,
            )

        if locked_until > now:
            remaining_seconds = max(
                1,
                math.ceil(
                    (
                        locked_until - now
                    ).total_seconds()
                ),
            )

            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=(
                    "Account temporarily locked after "
                    "5 failed login attempts. "
                    f"Please try again in "
                    f"{remaining_seconds} seconds."
                ),
            )

        # Lock period already expired.
        user.failed_login_attempts = 0
        user.locked_until = None

        db.commit()
        db.refresh(user)

    # --------------------------------------------------------
    # VERIFY PASSWORD
    # --------------------------------------------------------

    password_valid = verify_password(
        request.password,
        user.password_hash,
    )
    if not password_valid:
        user.failed_login_attempts = (
            user.failed_login_attempts or 0
        ) + 1

        # Fifth failed attempt locks the account.
        if user.failed_login_attempts >= MAX_LOGIN_ATTEMPTS:
            user.locked_until = (
                now + timedelta(
                    seconds=LOCKOUT_SECONDS,
                )
            )

            db.commit()
            db.refresh(user)

            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=(
                    "Account temporarily locked after "
                    "5 failed login attempts. "
                    "Please try again in 60 seconds."
                ),
            )

        attempts_remaining = (
            MAX_LOGIN_ATTEMPTS
            - user.failed_login_attempts
        )

        db.commit()
        db.refresh(user)

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=(
                "Invalid email or password. "
                f"{attempts_remaining} "
                f"{'attempt' if attempts_remaining == 1 else 'attempts'} "
                "remaining before temporary lock."
            ),
        )

    # --------------------------------------------------------
    # SUCCESSFUL LOGIN - RESET FAILED ATTEMPTS
    # --------------------------------------------------------

    user.failed_login_attempts = 0
    user.locked_until = None

    db.commit()
    db.refresh(user)

    if not user.is_email_verified:
        raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail=(
            "Please verify your email "
            "before logging in."
        ),
    )

    access_token = create_access_token(
        user_id=user.user_id,
        role=user.role,
    )

    return UserLoginResponse(
        access_token=access_token,
        token_type="bearer",
        user=AuthenticatedUserResponse(
            user_id=user.user_id,
            full_name=user.full_name,
            email=user.email,
            role=user.role,
            stakeholder_role=user.stakeholder_role,
            custom_role=user.custom_role,
        ),
    )