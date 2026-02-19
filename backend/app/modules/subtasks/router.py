from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import uuid

from app.core.deps import get_current_user
from app.db import models
from app.db.session import get_db
from app.repositories.serializers import orm_to_dict
from app.schemas.subtasks import SubtaskCreate, SubtaskOut, SubtaskUpdate
from app.services.sync_log_service import append_change

router = APIRouter(prefix="/tasks/{task_id}/subtasks", tags=["subtasks"])


@router.get("", response_model=list[SubtaskOut])
def list_subtasks(task_id: str, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    return (
        db.query(models.Subtask)
        .filter(
            models.Subtask.task_id == task_id,
            models.Subtask.user_id == user.id,
            models.Subtask.deleted_at.is_(None),
        )
        .order_by(models.Subtask.order_key.asc())
        .all()
    )


@router.post("", response_model=SubtaskOut, status_code=status.HTTP_201_CREATED)
def create_subtask(
    task_id: str,
    payload: SubtaskCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    task = db.query(models.Task).filter_by(id=task_id, user_id=user.id, deleted_at=None).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    row = models.Subtask(
        id=payload.id or str(uuid.uuid4()),
        user_id=user.id,
        task_id=task_id,
        title=payload.title,
        is_done=payload.is_done,
        order_key=payload.order_key,
        note=payload.note,
    )
    db.add(row)
    db.flush()
    append_change(db, user.id, "subtask", "upsert", row.id, record=orm_to_dict(row))
    db.commit()
    db.refresh(row)
    return row


@router.put("/{subtask_id}", response_model=SubtaskOut)
def update_subtask(
    task_id: str,
    subtask_id: str,
    payload: SubtaskUpdate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = (
        db.query(models.Subtask)
        .filter_by(id=subtask_id, task_id=task_id, user_id=user.id, deleted_at=None)
        .first()
    )
    if not row:
        raise HTTPException(status_code=404, detail="Subtask not found")

    if payload.title is not None:
        row.title = payload.title
    if payload.is_done is not None:
        row.is_done = payload.is_done
    if payload.order_key is not None:
        row.order_key = payload.order_key
    if payload.note is not None:
        row.note = payload.note
    db.flush()
    append_change(db, user.id, "subtask", "upsert", row.id, record=orm_to_dict(row))
    db.commit()
    db.refresh(row)
    return row


@router.delete("/{subtask_id}")
def delete_subtask(
    task_id: str,
    subtask_id: str,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = (
        db.query(models.Subtask)
        .filter_by(id=subtask_id, task_id=task_id, user_id=user.id, deleted_at=None)
        .first()
    )
    if not row:
        raise HTTPException(status_code=404, detail="Subtask not found")

    row.deleted_at = row.updated_at
    append_change(db, user.id, "subtask", "delete", row.id, deleted_meta={"deletedAt": row.deleted_at.isoformat()})
    db.commit()
    return {"message": "Deleted"}
