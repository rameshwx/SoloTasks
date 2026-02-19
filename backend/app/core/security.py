from __future__ import annotations

import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from jose import jwt

from app.core.config import get_settings


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def hash_value(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def generate_otp(length: int) -> str:
    max_value = 10**length - 1
    return f"{secrets.randbelow(max_value + 1):0{length}d}"


def generate_refresh_token() -> str:
    return secrets.token_urlsafe(48)


def create_access_token(user_id: str, email: str) -> str:
    settings = get_settings()
    expire = utcnow() + timedelta(minutes=settings.access_token_minutes)
    payload = {"sub": user_id, "email": email, "exp": expire, "type": "access"}
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str) -> dict:
    settings = get_settings()
    return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
