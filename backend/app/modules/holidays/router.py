from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import extract
import uuid

from app.core.deps import get_current_user
from app.db import models
from app.db.session import get_db
from app.repositories.serializers import orm_to_dict
from app.schemas.holidays import HolidayCreate, HolidayOut, HolidayUpdate
from app.services.sync_log_service import append_change

router = APIRouter(prefix="/holidays", tags=["holidays"])


@router.get("", response_model=list[HolidayOut])
def list_holidays(
    year: int | None = Query(default=None),
    type: models.HolidayType | None = Query(default=None),
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    q = db.query(models.Holiday).filter(models.Holiday.user_id == user.id, models.Holiday.deleted_at.is_(None))
    if year:
        q = q.filter(extract("year", models.Holiday.date_local) == year)
    if type:
        q = q.filter(models.Holiday.type == type)
    return q.order_by(models.Holiday.date_local.asc()).all()


@router.post("", response_model=HolidayOut, status_code=status.HTTP_201_CREATED)
def create_holiday(
    payload: HolidayCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = models.Holiday(
        id=payload.id or str(uuid.uuid4()),
        user_id=user.id,
        date_local=payload.date_local,
        type=payload.type,
        label=payload.label,
    )
    db.add(row)
    db.flush()
    append_change(db, user.id, "holiday", "upsert", row.id, record=orm_to_dict(row))
    db.commit()
    db.refresh(row)
    return row


@router.put("/{holiday_id}", response_model=HolidayOut)
def update_holiday(
    holiday_id: str,
    payload: HolidayUpdate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = db.query(models.Holiday).filter_by(id=holiday_id, user_id=user.id, deleted_at=None).first()
    if not row:
        raise HTTPException(status_code=404, detail="Holiday not found")
    row.label = payload.label
    db.flush()
    append_change(db, user.id, "holiday", "upsert", row.id, record=orm_to_dict(row))
    db.commit()
    db.refresh(row)
    return row


@router.delete("/{holiday_id}")
def delete_holiday(
    holiday_id: str,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = db.query(models.Holiday).filter_by(id=holiday_id, user_id=user.id, deleted_at=None).first()
    if not row:
        raise HTTPException(status_code=404, detail="Holiday not found")
    row.deleted_at = row.updated_at
    append_change(db, user.id, "holiday", "delete", row.id, deleted_meta={"deletedAt": row.deleted_at.isoformat()})
    db.commit()
    return {"message": "Deleted"}


@router.delete("/year/{year}/type/{holiday_type}")
def clear_holiday_type_for_year(
    year: int,
    holiday_type: models.HolidayType,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    rows = (
        db.query(models.Holiday)
        .filter(
            models.Holiday.user_id == user.id,
            models.Holiday.type == holiday_type,
            models.Holiday.deleted_at.is_(None),
            extract("year", models.Holiday.date_local) == year,
        )
        .all()
    )
    for row in rows:
        row.deleted_at = row.updated_at
        append_change(db, user.id, "holiday", "delete", row.id, deleted_meta={"deletedAt": row.deleted_at.isoformat()})
    db.commit()
    return {"deleted": len(rows)}
