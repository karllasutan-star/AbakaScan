from datetime import datetime, timedelta, timezone
import hashlib
import hmac
import secrets

import jwt
from jwt import InvalidTokenError
from pwdlib import PasswordHash

from app.core.config import settings


password_hash = PasswordHash.recommended()


# ============================================================
# PASSWORD SECURITY
# ============================================================

def hash_password(password: str) -> str:
    return password_hash.hash(password)


def verify_password(
    password: str,
    hashed_password: str,
) -> bool:
    return password_hash.verify(
        password,
        hashed_password,
    )


# ============================================================
# EMAIL VERIFICATION OTP
# ============================================================

def generate_email_verification_otp() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


def hash_email_verification_otp(
    otp: str,
) -> str:
    return hmac.new(
        settings.jwt_secret.encode("utf-8"),
        otp.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


def verify_email_verification_otp(
    otp: str,
    stored_hash: str,
) -> bool:
    calculated_hash = hash_email_verification_otp(
        otp,
    )

    return hmac.compare_digest(
        calculated_hash,
        stored_hash,
    )

# ============================================================
# PASSWORD RESET OTP
# ============================================================

def generate_password_reset_otp() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


def hash_password_reset_otp(
    otp: str,
) -> str:
    return hmac.new(
        settings.jwt_secret.encode("utf-8"),
        f"password-reset:{otp}".encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


def verify_password_reset_otp(
    otp: str,
    stored_hash: str,
) -> bool:
    calculated_hash = hash_password_reset_otp(
        otp,
    )

    return hmac.compare_digest(
        calculated_hash,
        stored_hash,
    )

# ============================================================
# JWT
# ============================================================

def create_access_token(
    user_id: int,
    role: str,
) -> str:
    expires_at = datetime.now(timezone.utc) + timedelta(
        minutes=settings.jwt_access_token_minutes
    )

    payload = {
        "sub": str(user_id),
        "role": role,
        "exp": expires_at,
    }

    return jwt.encode(
        payload,
        settings.jwt_secret,
        algorithm=settings.jwt_algorithm,
    )


def decode_access_token(token: str) -> dict:
    try:
        return jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
    except InvalidTokenError as error:
        raise ValueError(
            "Invalid or expired token."
        ) from error