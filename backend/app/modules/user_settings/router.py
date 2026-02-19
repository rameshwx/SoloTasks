from __future__ import annotations

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db import models
from app.db.session import get_db
from app.schemas.user_settings import UserPreferencesOut, UserPreferencesPayload
from app.services.sync_log_service import append_change

router = APIRouter(prefix="/settings", tags=["settings"])

_PREFERENCES_KEY = "mobile_preferences"


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _default_payload() -> UserPreferencesPayload:
    return UserPreferencesPayload()


@router.get("/preferences", response_model=UserPreferencesOut)
def get_preferences(
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = (
        db.query(models.UserSetting)
        .filter_by(user_id=user.id, key=_PREFERENCES_KEY)
        .first()
    )
    if not row:
        defaults = _default_payload()
        return UserPreferencesOut(
            reminderDefaults=defaults.reminder_defaults.model_dump(by_alias=True),
            calendarPrefs=defaults.calendar_prefs.model_dump(by_alias=True),
            holidayPrefs=defaults.holiday_prefs.model_dump(by_alias=True),
            updatedAt=_utcnow(),
        )

    try:
        payload = UserPreferencesPayload.model_validate(row.value or {})
    except Exception:
        payload = _default_payload()

    return UserPreferencesOut(
        reminderDefaults=payload.reminder_defaults.model_dump(by_alias=True),
        calendarPrefs=payload.calendar_prefs.model_dump(by_alias=True),
        holidayPrefs=payload.holiday_prefs.model_dump(by_alias=True),
        updatedAt=row.updated_at or _utcnow(),
    )


@router.put("/preferences", response_model=UserPreferencesOut)
def put_preferences(
    payload: UserPreferencesPayload,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = (
        db.query(models.UserSetting)
        .filter_by(user_id=user.id, key=_PREFERENCES_KEY)
        .first()
    )

    value = payload.model_dump(by_alias=True)
    if not row:
        row = models.UserSetting(
            id=str(uuid.uuid4()),
            user_id=user.id,
            key=_PREFERENCES_KEY,
            value=value,
        )
        db.add(row)
    else:
        row.value = value

    db.flush()
    append_change(
        db,
        user.id,
        "setting",
        "upsert",
        _PREFERENCES_KEY,
        record={"key": _PREFERENCES_KEY, "value": value},
    )
    db.commit()
    db.refresh(row)

    return UserPreferencesOut(
        reminderDefaults=payload.reminder_defaults.model_dump(by_alias=True),
        calendarPrefs=payload.calendar_prefs.model_dump(by_alias=True),
        holidayPrefs=payload.holiday_prefs.model_dump(by_alias=True),
        updatedAt=row.updated_at or _utcnow(),
    )

