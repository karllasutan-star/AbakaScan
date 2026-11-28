import logging
import smtplib
import ssl
from email.message import EmailMessage
from email.utils import formataddr

from app.core.config import settings


logger = logging.getLogger("uvicorn.error")


def _send_email(
    recipient_email: str,
    subject: str,
    body: str,
) -> None:
    required = {
        "SMTP_HOST": settings.smtp_host,
        "SMTP_USERNAME": settings.smtp_username,
        "SMTP_PASSWORD": settings.smtp_password,
        "SMTP_FROM_EMAIL": settings.smtp_from_email,
    }

    missing = [
        name
        for name, value in required.items()
        if not value
    ]

    if missing:
        logger.error(
            "Email configuration missing: %s",
            ", ".join(missing),
        )
        raise RuntimeError("Email service is not configured.")

    try:
        port = int(settings.smtp_port)
        if not 1 <= port <= 65535:
            raise ValueError
    except (TypeError, ValueError):
        logger.error("SMTP_PORT must be a valid port number.")
        raise RuntimeError("Invalid email service port.") from None

    message = EmailMessage()
    message["Subject"] = subject
    message["From"] = formataddr(
        (
            settings.smtp_from_name or "ABAKASCAN",
            settings.smtp_from_email,
        )
    )
    message["To"] = recipient_email
    message.set_content(body)

    tls_context = ssl.create_default_context()

    try:
        if port == 465:
            connection = smtplib.SMTP_SSL(
                settings.smtp_host,
                port,
                timeout=20,
                context=tls_context,
            )
        else:
            connection = smtplib.SMTP(
                settings.smtp_host,
                port,
                timeout=20,
            )

        with connection as server:
            server.ehlo()

            if port != 465:
                server.starttls(context=tls_context)
                server.ehlo()

            server.login(
                settings.smtp_username,
                settings.smtp_password,
            )
            server.send_message(message)

    except smtplib.SMTPAuthenticationError as error:
        logger.error(
            "SMTP authentication failed. Code: %s. "
            "Check the sender username, SMTP password, "
            "and email provider account settings.",
            error.smtp_code,
        )
        raise RuntimeError(
            "Email service authentication failed."
        ) from error

    except ssl.SSLError as error:
        logger.error(
            "SMTP TLS connection failed. "
            "Check the SMTP host, port, certificates, "
            "and computer date/time."
        )
        raise RuntimeError(
            "Unable to establish a secure email connection."
        ) from error

    except smtplib.SMTPException as error:
        logger.error(
            "SMTP sending failed. Type: %s; code: %s.",
            type(error).__name__,
            getattr(error, "smtp_code", "not provided"),
        )
        raise RuntimeError(
            "The email server could not send the message."
        ) from error

    except OSError as error:
        logger.error(
            "SMTP network connection failed. "
            "Type: %s; OS error: %s. "
            "Check the SMTP host, network, and firewall.",
            type(error).__name__,
            getattr(error, "errno", "not provided"),
        )
        raise RuntimeError(
            "Unable to connect to the email server."
        ) from error

    logger.info("OTP email accepted by the SMTP server.")


def send_verification_email(
    recipient_email: str,
    otp: str,
) -> None:
    _send_email(
        recipient_email=recipient_email,
        subject="Verify your ABAKASCAN email",
        body=(
            "Hello,\n\n"
            "Your ABAKASCAN email verification code is:\n\n"
            f"{otp}\n\n"
            "This code will expire in "
            f"{settings.email_verification_otp_minutes} minutes.\n\n"
            "If you did not create an ABAKASCAN account, "
            "you can ignore this email.\n\n"
            "ABAKASCAN"
        ),
    )


def send_password_reset_email(
    recipient_email: str,
    otp: str,
) -> None:
    _send_email(
        recipient_email=recipient_email,
        subject="Reset your ABAKASCAN password",
        body=(
            "Hello,\n\n"
            "Your ABAKASCAN password reset code is:\n\n"
            f"{otp}\n\n"
            "This code will expire in "
            f"{settings.password_reset_otp_minutes} minutes.\n\n"
            "If you did not request a password reset, "
            "you can ignore this email.\n\n"
            "ABAKASCAN"
        ),
    )