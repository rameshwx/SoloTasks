from __future__ import annotations

from datetime import date
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db import models
from app.db.session import get_db
from app.repositories.serializers import orm_to_dict
from app.schemas.tasks import (
    TaskCreate,
    TaskOut,
    TaskSeriesCreate,
    TaskSeriesCreateResponse,
    TaskUpdate,
)
from app.services.series_service import build_series_tasks
from app.services.sync_log_service import append_change
from app.services.validation import validate_task_window

router = APIRouter(prefix="/tasks", tags=["tasks"])


@router.get("", response_model=list[TaskOut])
def list_tasks(
    start_date: date | None = Query(default=None, alias="startDate"),
    end_date: date | None = Query(default=None, alias="endDate"),
    status_filter: models.TaskStatus | None = Query(default=None, alias="status"),
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    q = db.query(models.Task).filter(models.Task.user_id == user.id, models.Task.deleted_at.is_(None))
    if start_date:
        q = q.filter(models.Task.date_local >= start_date)
    if end_date:
        q = q.filter(models.Task.date_local <= end_date)
    if status_filter:
        q = q.filter(models.Task.status == status_filter)
    return q.order_by(models.Task.date_local.asc(), models.Task.start_min.asc()).all()


@router.post("", response_model=TaskOut, status_code=status.HTTP_201_CREATED)
def create_task(
    payload: TaskCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    validate_task_window(payload.start_min, payload.end_min, payload.duration_min)
    row = models.Task(
        id=payload.id or str(uuid.uuid4()),
        user_id=user.id,
        title=payload.title,
        description=payload.description,
        status=payload.status,
        date_local=payload.date_local,
        start_min=payload.start_min,
        end_min=payload.end_min,
        duration_min=payload.duration_min,
        series_id=payload.series_id,
        series_index=payload.series_index,
        series_total=payload.series_total,
    )
    db.add(row)
    db.flush()
    append_change(db, user.id, "task", "upsert", row.id, record=orm_to_dict(row))
    db.commit()
    db.refresh(row)
    return row


@router.get("/{task_id}", response_model=TaskOut)
def get_task(
    task_id: str,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = db.query(models.Task).filter_by(id=task_id, user_id=user.id, deleted_at=None).first()
    if not row:
        raise HTTPException(status_code=404, detail="Task not found")
    return row


@router.put("/{task_id}", response_model=TaskOut)
def update_task(
    task_id: str,
    payload: TaskUpdate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = db.query(models.Task).filter_by(id=task_id, user_id=user.id, deleted_at=None).first()
    if not row:
        raise HTTPException(status_code=404, detail="Task not found")

    if payload.title is not None:
        row.title = payload.title
    if payload.description is not None:
        row.description = payload.description
    if payload.status is not None:
        row.status = payload.status
    if payload.date_local is not None:
        row.date_local = payload.date_local
    if payload.start_min is not None:
        row.start_min = payload.start_min
    if payload.end_min is not None:
        row.end_min = payload.end_min
    if payload.duration_min is not None:
        row.duration_min = payload.duration_min

    validate_task_window(row.start_min, row.end_min, row.duration_min)

    db.flush()
    append_change(db, user.id, "task", "upsert", row.id, record=orm_to_dict(row))
    db.commit()
    db.refresh(row)
    return row


@router.delete("/{task_id}")
def delete_task(
    task_id: str,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = db.query(models.Task).filter_by(id=task_id, user_id=user.id, deleted_at=None).first()
    if not row:
        raise HTTPException(status_code=404, detail="Task not found")
    row.deleted_at = row.updated_at
    append_change(db, user.id, "task", "delete", row.id, deleted_meta={"deletedAt": row.deleted_at.isoformat()})

    attachments = (
        db.query(models.Attachment)
        .filter(models.Attachment.task_id == row.id, models.Attachment.user_id == user.id, models.Attachment.deleted_at.is_(None))
        .all()
    )
    for att in attachments:
        att.deleted_at = att.updated_at
        append_change(
            db,
            user.id,
            "attachment",
            "delete",
            att.id,
            deleted_meta={"deletedAt": att.deleted_at.isoformat(), "taskId": row.id},
        )

    db.commit()
    return {"message": "Deleted"}


@router.post("/series", response_model=TaskSeriesCreateResponse, status_code=status.HTTP_201_CREATED)
def create_task_series(
    payload: TaskSeriesCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    validate_task_window(payload.start_min, payload.end_min, payload.duration_min)
    series_id, tasks = build_series_tasks(user.id, payload)
    for t in tasks:
        db.add(t)
        db.flush()
        append_change(db, user.id, "task", "upsert", t.id, record=orm_to_dict(t))
    db.commit()
    return TaskSeriesCreateResponse(seriesId=series_id, total=len(tasks), tasks=[TaskOut.model_validate(x) for x in tasks])


@router.put("/{task_id}/series")
def update_series(
    task_id: str,
    mode: str = Query(..., pattern="^(this|future|all)$"),
    payload: TaskUpdate | None = None,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    payload = payload or TaskUpdate()
    task = db.query(models.Task).filter_by(id=task_id, user_id=user.id, deleted_at=None).first()
    if not task or not task.series_id:
        raise HTTPException(status_code=404, detail="Series task not found")

    q = db.query(models.Task).filter(
        models.Task.user_id == user.id,
        models.Task.series_id == task.series_id,
        models.Task.deleted_at.is_(None),
    )
    if mode == "this":
        q = q.filter(models.Task.id == task.id)
    elif mode == "future":
        q = q.filter(models.Task.series_index >= task.series_index)

    rows = q.order_by(models.Task.series_index.asc()).all()
    for row in rows:
        if payload.title is not None:
            row.title = payload.title
        if payload.description is not None:
            row.description = payload.description
        if payload.date_local is not None and mode == "this":
            row.date_local = payload.date_local
        if payload.start_min is not None:
            row.start_min = payload.start_min
        if payload.end_min is not None:
            row.end_min = payload.end_min
        if payload.duration_min is not None:
            row.duration_min = payload.duration_min
        validate_task_window(row.start_min, row.end_min, row.duration_min)
        append_change(db, user.id, "task", "upsert", row.id, record=orm_to_dict(row))

    db.commit()
    return {"updated": len(rows)}
