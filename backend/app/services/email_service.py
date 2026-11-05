import smtplib
from email.message import EmailMessage

from app.core.config import settings


def send_verification_email(
    recipient_email: str,
    otp: str,
) -> None:
    if not settings.smtp_username:
        raise RuntimeError(
            "SMTP_USERNAME is not configured."
        )

    if not settings.smtp_password:
        raise RuntimeError(
            "SMTP_PASSWORD is not configured."
        )

    if not settings.smtp_from_email:
        raise RuntimeError(
            "SMTP_FROM_EMAIL is not configured."
        )

    message = EmailMessage()

    message["Subject"] = "Verify your ABAKASCAN email"
    message["From"] = (
        f"{settings.smtp_from_name} "
        f"<{settings.smtp_from_email}>"
    )
    message["To"] = recipient_email

    message.set_content(
        
        f"""
Hello,

Your ABAKASCAN email verification code is:

{otp}

This code will expire in
{settings.email_verification_otp_minutes} minutes.

If you did not create an ABAKASCAN account,
you can ignore this email.

ABAKASCAN
""".strip()
    )

    try:
        with smtplib.SMTP(
            settings.smtp_host,
            settings.smtp_port,
            timeout=20,
        ) as server:
            server.ehlo()
            server.starttls()
            server.ehlo()

            server.login(
                settings.smtp_username,
                settings.smtp_password,
            )

            server.send_message(message)

    except smtplib.SMTPException as error:
        raise RuntimeError(
            "Unable to send verification email."
        ) from error


def send_password_reset_email(
    recipient_email: str,
    otp: str,
) -> None:
    if not settings.smtp_username:
        raise RuntimeError(
            "SMTP_USERNAME is not configured."
        )

    if not settings.smtp_password:
        raise RuntimeError(
            "SMTP_PASSWORD is not configured."
        )

    if not settings.smtp_from_email:
        raise RuntimeError(
            "SMTP_FROM_EMAIL is not configured."
        )

    message = EmailMessage()

    message["Subject"] = "Reset your ABAKASCAN password"
    message["From"] = (
        f"{settings.smtp_from_name} "
        f"<{settings.smtp_from_email}>"
    )
    message["To"] = recipient_email

    message.set_content(
        f"""
Hello,

Your ABAKASCAN password reset code is:

{otp}

This code will expire in
{settings.password_reset_otp_minutes} minutes.

If you did not request a password reset,
you can ignore this email.

ABAKASCAN
""".strip()
    )

    try:
        with smtplib.SMTP(
            settings.smtp_host,
            settings.smtp_port,
            timeout=20,
        ) as server:
            server.ehlo()
            server.starttls()
            server.ehlo()

            server.login(
                settings.smtp_username,
                settings.smtp_password,
            )

            server.send_message(message)

    except smtplib.SMTPException as error:
        raise RuntimeError(
            "Unable to send password reset email."
        ) from error