from __future__ import annotations

from datetime import timedelta

from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.security import utcnow
from app.db import models


def purge_old_tombstones(db: Session) -> dict[str, int]:
    settings = get_settings()
    cutoff = utcnow() - timedelta(days=settings.tombstone_retention_days)

    counters = {
        "tasks": db.query(models.Task).filter(models.Task.deleted_at.is_not(None), models.Task.deleted_at < cutoff).delete(),
        "subtasks": db.query(models.Subtask).filter(models.Subtask.deleted_at.is_not(None), models.Subtask.deleted_at < cutoff).delete(),
        "tags": db.query(models.Tag).filter(models.Tag.deleted_at.is_not(None), models.Tag.deleted_at < cutoff).delete(),
        "reminders": db.query(models.Reminder).filter(models.Reminder.deleted_at.is_not(None), models.Reminder.deleted_at < cutoff).delete(),
        "attachments": db.query(models.Attachment).filter(models.Attachment.deleted_at.is_not(None), models.Attachment.deleted_at < cutoff).delete(),
        "holidays": db.query(models.Holiday).filter(models.Holiday.deleted_at.is_not(None), models.Holiday.deleted_at < cutoff).delete(),
        "smart_lists": db.query(models.SmartList).filter(models.SmartList.deleted_at.is_not(None), models.SmartList.deleted_at < cutoff).delete(),
    }
    db.commit()
    return counters
