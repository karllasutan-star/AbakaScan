from pydantic import BaseModel, EmailStr, Field, model_validator


# ============================================================
# ALLOWED STAKEHOLDER ROLES
# ============================================================

ALLOWED_STAKEHOLDER_ROLES = {
    "FARMER",
    "FIBER_PROCESSOR",
    "COOPERATIVE",
    "BUYER",
    "AGRICULTURAL_RESEARCHER",
    "OTHERS",
}


# ============================================================
# REGISTER REQUEST
# ============================================================

class UserRegisterRequest(BaseModel):
    full_name: str = Field(
        min_length=2,
        max_length=150,
    )

    email: EmailStr

    password: str = Field(
        min_length=8,
        max_length=128,
    )

    stakeholder_role: str

    custom_role: str | None = None

    @model_validator(mode="after")
    def validate_registration(self):
        self.full_name = self.full_name.strip()
        self.email = str(self.email).strip().lower()

        if self.stakeholder_role not in ALLOWED_STAKEHOLDER_ROLES:
            raise ValueError(
                "Invalid stakeholder role."
            )

        if self.stakeholder_role == "OTHERS":
            if (
                self.custom_role is None
                or not self.custom_role.strip()
            ):
                raise ValueError(
                    "Custom role is required when stakeholder role is Others."
                )

            self.custom_role = self.custom_role.strip()

        else:
            self.custom_role = None

        return self


# ============================================================
# REGISTER RESPONSE
# ============================================================

class UserRegisterResponse(BaseModel):
    user_id: int
    full_name: str
    email: str
    role: str
    stakeholder_role: str | None
    custom_role: str | None
    message: str

# ============================================================
# REGISTRATION VERIFICATION RESPONSE
# ============================================================

class RegistrationPendingResponse(BaseModel):
    message: str
    email: EmailStr
    verification_required: bool = True


# ============================================================
# VERIFY EMAIL REQUEST
# ============================================================

class VerifyEmailRequest(BaseModel):
    email: EmailStr

    otp: str = Field(
        min_length=6,
        max_length=6,
        pattern=r"^\d{6}$",
    )


# ============================================================
# RESEND VERIFICATION REQUEST
# ============================================================

class ResendVerificationRequest(BaseModel):
    email: EmailStr


# ============================================================
# EMAIL VERIFICATION RESPONSE
# ============================================================

class EmailVerificationResponse(BaseModel):
    message: str
    email: EmailStr
    verified: bool


# ============================================================
# PASSWORD RESET REQUESTS
# ============================================================

class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr

    otp: str = Field(
        min_length=6,
        max_length=6,
        pattern=r"^\d{6}$",
    )

    new_password: str = Field(
        min_length=8,
        max_length=128,
    )


# ============================================================
# PASSWORD RESET RESPONSE
# ============================================================

class PasswordResetResponse(BaseModel):
    message: str
    email: EmailStr
    reset: bool
# ============================================================
# LOGIN REQUEST
# ============================================================

class UserLoginRequest(BaseModel):
    identifier: str = Field(
        min_length=1,
        max_length=190,
    )

    password: str = Field(
        min_length=1,
        max_length=128,
    )


# ============================================================
# AUTHENTICATED USER
# ============================================================

class AuthenticatedUserResponse(BaseModel):
    user_id: int
    full_name: str
    email: str
    role: str
    stakeholder_role: str | None
    custom_role: str | None


# ============================================================
# LOGIN RESPONSE
# ============================================================

class UserLoginResponse(BaseModel):
    access_token: str
    token_type: str
    user: AuthenticatedUserResponse