from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class RequestOtpInput(BaseModel):
    email: EmailStr


class RequestOtpResponse(BaseModel):
    model_config = {"populate_by_name": True}
    cooldown_sec: int = Field(alias="cooldownSec")
    expires_at: datetime = Field(alias="expiresAt")


class VerifyOtpInput(BaseModel):
    model_config = {"populate_by_name": True}
    email: EmailStr
    otp: str
    device_id: str = Field(alias="deviceId")
    device_name: str | None = Field(default=None, alias="deviceName")


class RefreshInput(BaseModel):
    model_config = {"populate_by_name": True}
    refresh_token: str = Field(alias="refreshToken")


class LogoutInput(BaseModel):
    model_config = {"populate_by_name": True}
    refresh_token: str = Field(alias="refreshToken")


class UserOut(BaseModel):
    id: str
    email: EmailStr
    timezone: str

    model_config = {"from_attributes": True}


class VerifyOtpResponse(BaseModel):
    model_config = {"populate_by_name": True}
    access_token: str = Field(alias="accessToken")
    refresh_token: str = Field(alias="refreshToken")
    user: UserOut
    timezone: str


class RefreshResponse(BaseModel):
    model_config = {"populate_by_name": True}
    access_token: str = Field(alias="accessToken")
