from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db import models
from app.db.session import get_db
from app.schemas.sync import ChangeOut, SyncPullResponse, SyncPushInput, SyncPushResponse
from app.sync.service import SyncService

router = APIRouter(prefix="/sync", tags=["sync"])


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


@router.post("/push", response_model=SyncPushResponse)
def push(
    payload: SyncPushInput,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    service = SyncService(db)
    applied_count, rejected = service.apply_ops(user.id, payload.ops)
    return SyncPushResponse(serverTime=utcnow(), appliedCount=applied_count, rejectedOps=rejected)


@router.get("/pull", response_model=SyncPullResponse)
def pull(
    cursor: int = Query(default=0),
    device_id: str = Query(alias="deviceId"),
    limit: int = Query(default=500, le=1000),
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    _ = device_id
    rows = (
        db.query(models.SyncChange)
        .filter(models.SyncChange.user_id == user.id, models.SyncChange.seq > cursor)
        .order_by(models.SyncChange.seq.asc())
        .limit(limit)
        .all()
    )

    changes = [
        ChangeOut(
            seq=row.seq,
            entity=row.entity,
            action=row.action,
            entityId=row.entity_id,
            record=row.record_json,
            deletedMeta=row.deleted_meta_json,
        )
        for row in rows
    ]
    next_cursor = rows[-1].seq if rows else cursor
    return SyncPullResponse(cursor=next_cursor, serverTime=utcnow(), changes=changes)
