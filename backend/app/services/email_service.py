from __future__ import annotations

import asyncio
import logging
from email.message import EmailMessage

import aiosmtplib

from app.core.config import get_settings

logger = logging.getLogger(__name__)


async def send_otp_email(email: str, otp: str) -> None:
    settings = get_settings()
    sender = (settings.otp_from_email or settings.smtp_username).strip()
    message = EmailMessage()
    message["From"] = sender
    message["To"] = email
    message["Subject"] = "Your SoloTasks verification code"
    message.set_content(
        f"Your verification code is {otp}. It expires in {settings.otp_expires_minutes} minutes."
    )

    try:
        response = await aiosmtplib.send(
            message,
            sender=settings.smtp_username,
            recipients=[email],
            hostname=settings.smtp_host,
            port=settings.smtp_port,
            username=settings.smtp_username,
            password=settings.smtp_password,
            use_tls=settings.smtp_use_tls,
        )
        logger.info("OTP email accepted by SMTP for %s (%s)", email, response[1] if len(response) > 1 else "ok")
    except Exception:
        logger.exception("Failed sending OTP email to %s", email)
        raise


def send_otp_email_bg(email: str, otp: str) -> None:
    # Run async SMTP in a dedicated loop from sync FastAPI handlers.
    asyncio.run(send_otp_email(email, otp))
