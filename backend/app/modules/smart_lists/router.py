from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db import models
from app.db.session import get_db
from app.repositories.serializers import orm_to_dict
from app.services.sync_log_service import append_change

router = APIRouter(prefix="/smart-lists", tags=["smart-lists"])


class SmartListInput(BaseModel):
    name: str
    filters: dict


@router.get("")
def list_smart_lists(db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    return (
        db.query(models.SmartList)
        .filter(models.SmartList.user_id == user.id, models.SmartList.deleted_at.is_(None))
        .all()
    )


@router.post("", status_code=status.HTTP_201_CREATED)
def create_smart_list(
    payload: SmartListInput,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = models.SmartList(user_id=user.id, name=payload.name, filters=payload.filters)
    db.add(row)
    db.flush()
    append_change(db, user.id, "smart_list", "upsert", row.id, record=orm_to_dict(row))
    db.commit()
    return row


@router.put("/{smart_list_id}")
def update_smart_list(
    smart_list_id: str,
    payload: SmartListInput,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = db.query(models.SmartList).filter_by(id=smart_list_id, user_id=user.id, deleted_at=None).first()
    if not row:
        raise HTTPException(status_code=404, detail="Smart list not found")
    row.name = payload.name
    row.filters = payload.filters
    append_change(db, user.id, "smart_list", "upsert", row.id, record=orm_to_dict(row))
    db.commit()
    return row


@router.delete("/{smart_list_id}")
def delete_smart_list(
    smart_list_id: str,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = db.query(models.SmartList).filter_by(id=smart_list_id, user_id=user.id, deleted_at=None).first()
    if not row:
        raise HTTPException(status_code=404, detail="Smart list not found")
    row.deleted_at = row.updated_at
    append_change(db, user.id, "smart_list", "delete", row.id, deleted_meta={"deletedAt": row.deleted_at.isoformat()})
    db.commit()
    return {"message": "Deleted"}
