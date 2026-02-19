from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import uuid

from app.core.deps import get_current_user
from app.db import models
from app.db.session import get_db
from app.repositories.serializers import orm_to_dict
from app.schemas.reminders import ReminderCreate, ReminderOut, ReminderUpdate
from app.services.sync_log_service import append_change

router = APIRouter(prefix="/reminders", tags=["reminders"])


@router.get("", response_model=list[ReminderOut])
def list_reminders(db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    return (
        db.query(models.Reminder)
        .filter(models.Reminder.user_id == user.id, models.Reminder.deleted_at.is_(None))
        .all()
    )


@router.post("", response_model=ReminderOut, status_code=status.HTTP_201_CREATED)
def create_reminder(
    payload: ReminderCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = models.Reminder(
        id=payload.id or str(uuid.uuid4()),
        user_id=user.id,
        target_type=payload.target_type,
        target_id=payload.target_id,
        trigger_at_utc=payload.trigger_at_utc,
        offset_min_from_task_start=payload.offset_min_from_task_start,
    )
    db.add(row)
    db.flush()
    append_change(db, user.id, "reminder", "upsert", row.id, record=orm_to_dict(row))
    db.commit()
    db.refresh(row)
    return row


@router.put("/{reminder_id}", response_model=ReminderOut)
def update_reminder(
    reminder_id: str,
    payload: ReminderUpdate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = db.query(models.Reminder).filter_by(id=reminder_id, user_id=user.id, deleted_at=None).first()
    if not row:
        raise HTTPException(status_code=404, detail="Reminder not found")
    if payload.trigger_at_utc is not None:
        row.trigger_at_utc = payload.trigger_at_utc
    if payload.offset_min_from_task_start is not None:
        row.offset_min_from_task_start = payload.offset_min_from_task_start
    db.flush()
    append_change(db, user.id, "reminder", "upsert", row.id, record=orm_to_dict(row))
    db.commit()
    db.refresh(row)
    return row


@router.delete("/{reminder_id}")
def delete_reminder(
    reminder_id: str,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = db.query(models.Reminder).filter_by(id=reminder_id, user_id=user.id, deleted_at=None).first()
    if not row:
        raise HTTPException(status_code=404, detail="Reminder not found")
    row.deleted_at = row.updated_at
    append_change(db, user.id, "reminder", "delete", row.id, deleted_meta={"deletedAt": row.deleted_at.isoformat()})
    db.commit()
    return {"message": "Deleted"}
