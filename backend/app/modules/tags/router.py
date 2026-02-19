from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db import models
from app.db.session import get_db
from app.repositories.serializers import orm_to_dict
from app.schemas.tags import TagCreate, TagOut, TagUpdate
from app.services.sync_log_service import append_change

router = APIRouter(prefix="/tags", tags=["tags"])


@router.get("", response_model=list[TagOut])
def list_tags(
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    return (
        db.query(models.Tag)
        .filter(models.Tag.user_id == user.id, models.Tag.deleted_at.is_(None))
        .order_by(models.Tag.name.asc())
        .all()
    )


@router.post("", response_model=TagOut, status_code=status.HTTP_201_CREATED)
def create_tag(
    payload: TagCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = models.Tag(user_id=user.id, name=payload.name.strip(), color=payload.color)
    db.add(row)
    db.flush()
    append_change(db, user.id, "tag", "upsert", row.id, record=orm_to_dict(row))
    db.commit()
    db.refresh(row)
    return row


@router.put("/{tag_id}", response_model=TagOut)
def update_tag(
    tag_id: str,
    payload: TagUpdate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = db.query(models.Tag).filter_by(id=tag_id, user_id=user.id, deleted_at=None).first()
    if not row:
        raise HTTPException(status_code=404, detail="Tag not found")
    if payload.name is not None:
        row.name = payload.name.strip()
    if payload.color is not None:
        row.color = payload.color
    db.flush()
    append_change(db, user.id, "tag", "upsert", row.id, record=orm_to_dict(row))
    db.commit()
    db.refresh(row)
    return row


@router.delete("/{tag_id}")
def delete_tag(
    tag_id: str,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = db.query(models.Tag).filter_by(id=tag_id, user_id=user.id, deleted_at=None).first()
    if not row:
        raise HTTPException(status_code=404, detail="Tag not found")
    row.deleted_at = row.updated_at
    append_change(db, user.id, "tag", "delete", row.id, deleted_meta={"deletedAt": row.deleted_at.isoformat()})
    db.commit()
    return {"message": "Deleted"}
