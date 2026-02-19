from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.auth import (
    LogoutInput,
    RefreshInput,
    RefreshResponse,
    RequestOtpInput,
    RequestOtpResponse,
    VerifyOtpInput,
    VerifyOtpResponse,
    UserOut,
)
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/request-otp", response_model=RequestOtpResponse)
def request_otp(payload: RequestOtpInput, db: Session = Depends(get_db)):
    service = AuthService(db)
    cooldown, expires_at = service.request_otp(payload.email)
    return RequestOtpResponse(cooldownSec=cooldown, expiresAt=expires_at)


@router.post("/verify-otp", response_model=VerifyOtpResponse)
def verify_otp(payload: VerifyOtpInput, db: Session = Depends(get_db)):
    service = AuthService(db)
    access_token, refresh_token, user = service.verify_otp(
        payload.email, payload.otp, payload.device_id, payload.device_name
    )
    return VerifyOtpResponse(
        accessToken=access_token,
        refreshToken=refresh_token,
        user=UserOut.model_validate(user),
        timezone=user.timezone,
    )


@router.post("/refresh", response_model=RefreshResponse)
def refresh(payload: RefreshInput, db: Session = Depends(get_db)):
    service = AuthService(db)
    access_token = service.refresh(payload.refresh_token)
    return RefreshResponse(accessToken=access_token)


@router.post("/logout")
def logout(payload: LogoutInput, db: Session = Depends(get_db)):
    service = AuthService(db)
    service.logout(payload.refresh_token)
    return {"message": "Logged out"}
