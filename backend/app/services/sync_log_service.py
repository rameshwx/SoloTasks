from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.db import models


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def append_change(
    db: Session,
    user_id: str,
    entity: str,
    action: str,
    entity_id: str,
    record: dict | None = None,
    deleted_meta: dict | None = None,
) -> models.SyncChange:
    change = models.SyncChange(
        user_id=user_id,
        entity=entity,
        action=action,
        entity_id=entity_id,
        record_json=record,
        deleted_meta_json=deleted_meta,
    )
    db.add(change)
    db.flush()
    return change
