from __future__ import annotations

from datetime import timedelta

from fastapi import HTTPException, status
from sqlalchemy import and_
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.security import (
    create_access_token,
    generate_otp,
    generate_refresh_token,
    hash_value,
    utcnow,
)
from app.db import models
from app.services.email_service import send_otp_email_bg


class AuthService:
    def __init__(self, db: Session):
        self.db = db
        self.settings = get_settings()

    def request_otp(self, email: str) -> tuple[int, object]:
        now = utcnow()

        window_start = now - timedelta(minutes=self.settings.otp_throttle_window_minutes)
        recent_count = (
            self.db.query(models.OtpCode)
            .filter(and_(models.OtpCode.email == email, models.OtpCode.created_at >= window_start))
            .count()
        )
        if recent_count >= self.settings.otp_max_per_window:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many OTP requests. Try later.",
            )

        latest = (
            self.db.query(models.OtpCode)
            .filter(models.OtpCode.email == email)
            .order_by(models.OtpCode.created_at.desc())
            .first()
        )
        if latest:
            elapsed = (now - latest.created_at).total_seconds()
            if elapsed < self.settings.otp_resend_cooldown_seconds:
                cooldown = int(self.settings.otp_resend_cooldown_seconds - elapsed)
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail={"cooldownSec": cooldown},
                )

        otp = generate_otp(self.settings.otp_length)
        code = models.OtpCode(
            email=email,
            code_hash=hash_value(otp),
            expires_at=now + timedelta(minutes=self.settings.otp_expires_minutes),
        )
        self.db.add(code)
        self.db.commit()

        send_otp_email_bg(email, otp)

        return self.settings.otp_resend_cooldown_seconds, code.expires_at

    def verify_otp(self, email: str, otp: str, device_id: str, device_name: str | None):
        now = utcnow()
        code = (
            self.db.query(models.OtpCode)
            .filter(
                models.OtpCode.email == email,
                models.OtpCode.consumed_at.is_(None),
                models.OtpCode.expires_at > now,
            )
            .order_by(models.OtpCode.created_at.desc())
            .first()
        )
        if not code or code.code_hash != hash_value(otp):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid OTP")

        code.consumed_at = now

        user = self.db.query(models.User).filter(models.User.email == email).first()
        if not user:
            user = models.User(email=email, timezone=self.settings.default_timezone)
            self.db.add(user)
            self.db.flush()

        refresh_token = generate_refresh_token()
        session = models.RefreshSession(
            user_id=user.id,
            token_hash=hash_value(refresh_token),
            device_id=device_id,
            device_name=device_name,
            expires_at=now + timedelta(days=self.settings.refresh_token_days),
        )
        self.db.add(session)
        self.db.commit()

        access_token = create_access_token(user.id, user.email)
        return access_token, refresh_token, user

    def refresh(self, refresh_token: str) -> str:
        token_hash = hash_value(refresh_token)
        now = utcnow()
        session = (
            self.db.query(models.RefreshSession)
            .filter(
                models.RefreshSession.token_hash == token_hash,
                models.RefreshSession.revoked_at.is_(None),
                models.RefreshSession.expires_at > now,
            )
            .first()
        )
        if not session:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

        user = self.db.query(models.User).filter(models.User.id == session.user_id).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

        return create_access_token(user.id, user.email)

    def logout(self, refresh_token: str) -> None:
        token_hash = hash_value(refresh_token)
        session = (
            self.db.query(models.RefreshSession)
            .filter(models.RefreshSession.token_hash == token_hash, models.RefreshSession.revoked_at.is_(None))
            .first()
        )
        if session:
            session.revoked_at = utcnow()
            self.db.commit()
