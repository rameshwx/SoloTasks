from __future__ import annotations

import mimetypes
import uuid

from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.responses import FileResponse, RedirectResponse
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.deps import get_current_user
from app.db import models
from app.db.session import get_db
from app.repositories.serializers import orm_to_dict
from app.schemas.attachments import AttachmentCreate, AttachmentOut, UploadInitInput, UploadInitResponse
from app.services.sync_log_service import append_change
from app.storage.factory import get_storage

router = APIRouter(tags=["attachments"])


@router.get("/tasks/{task_id}/attachments", response_model=list[AttachmentOut])
def list_task_attachments(task_id: str, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    return (
        db.query(models.Attachment)
        .filter(
            models.Attachment.task_id == task_id,
            models.Attachment.user_id == user.id,
            models.Attachment.deleted_at.is_(None),
        )
        .all()
    )


@router.post("/tasks/{task_id}/attachments", response_model=AttachmentOut, status_code=status.HTTP_201_CREATED)
def create_task_attachment(
    task_id: str,
    payload: AttachmentCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    task = db.query(models.Task).filter_by(id=task_id, user_id=user.id, deleted_at=None).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    row = models.Attachment(
        id=payload.id or str(uuid.uuid4()),
        user_id=user.id,
        task_id=task_id,
        type=payload.type,
        name=payload.name,
        size=payload.size,
        remote_key=payload.remote_key,
        cached_path=payload.cached_path,
        keep_offline=payload.keep_offline,
    )
    db.add(row)
    db.flush()
    append_change(db, user.id, "attachment", "upsert", row.id, record=orm_to_dict(row))
    db.commit()
    db.refresh(row)
    return row


@router.delete("/tasks/{task_id}/attachments/{attachment_id}")
def delete_task_attachment(
    task_id: str,
    attachment_id: str,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    storage = get_storage()
    row = (
        db.query(models.Attachment)
        .filter_by(id=attachment_id, task_id=task_id, user_id=user.id, deleted_at=None)
        .first()
    )
    if not row:
        raise HTTPException(status_code=404, detail="Attachment not found")

    storage.delete(row.remote_key)
    row.deleted_at = row.updated_at
    append_change(db, user.id, "attachment", "delete", row.id, deleted_meta={"deletedAt": row.deleted_at.isoformat()})
    db.commit()
    return {"message": "Deleted"}


@router.post("/attachments/upload-init", response_model=UploadInitResponse)
def upload_init(
    payload: UploadInitInput,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    settings = get_settings()
    task = db.query(models.Task).filter_by(id=payload.task_id, user_id=user.id, deleted_at=None).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    mime = payload.mime_type.lower()
    if mime.startswith("image/") and payload.size > settings.max_image_bytes:
        raise HTTPException(status_code=400, detail="Image exceeds max size")
    if mime == "application/pdf" and payload.size > settings.max_pdf_bytes:
        raise HTTPException(status_code=400, detail="PDF exceeds max size")

    attachment_type = models.AttachmentType.image if mime.startswith("image/") else models.AttachmentType.pdf
    attachment_id = str(uuid.uuid4())
    remote_key = f"users/{user.id}/tasks/{payload.task_id}/{attachment_id}-{payload.file_name}"

    row = models.Attachment(
        id=attachment_id,
        user_id=user.id,
        task_id=payload.task_id,
        type=attachment_type,
        name=payload.file_name,
        size=payload.size,
        remote_key=remote_key,
    )
    db.add(row)
    db.flush()
    append_change(db, user.id, "attachment", "upsert", row.id, record=orm_to_dict(row))

    descriptor = get_storage().make_upload_descriptor(remote_key, mime, attachment_id)
    db.commit()
    return UploadInitResponse(
        attachmentId=attachment_id,
        uploadUrl=descriptor.upload_url,
        remoteKey=remote_key,
        method=descriptor.method,
        headers=descriptor.headers,
    )


@router.put("/attachments/{attachment_id}/upload")
async def local_upload(
    attachment_id: str,
    request: Request,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = db.query(models.Attachment).filter_by(id=attachment_id, user_id=user.id, deleted_at=None).first()
    if not row:
        raise HTTPException(status_code=404, detail="Attachment not found")

    data = await request.body()
    mime, _ = mimetypes.guess_type(row.name)
    get_storage().save_bytes(row.remote_key, data, mime or "application/octet-stream")
    return {"message": "Uploaded"}


@router.get("/attachments/{attachment_id}/download")
def download_attachment(
    attachment_id: str,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    row = db.query(models.Attachment).filter_by(id=attachment_id, user_id=user.id, deleted_at=None).first()
    if not row:
        raise HTTPException(status_code=404, detail="Attachment not found")

    storage = get_storage()
    signed_url = storage.make_download_url(row.remote_key)
    if signed_url:
        return RedirectResponse(signed_url)

    local_path = storage.open_local_path(row.remote_key)
    if not local_path:
        raise HTTPException(status_code=404, detail="File missing")

    return FileResponse(local_path, filename=row.name)


@router.delete("/attachments/{attachment_id}")
def delete_attachment(
    attachment_id: str,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    storage = get_storage()
    row = db.query(models.Attachment).filter_by(id=attachment_id, user_id=user.id, deleted_at=None).first()
    if not row:
        raise HTTPException(status_code=404, detail="Attachment not found")
    storage.delete(row.remote_key)
    row.deleted_at = row.updated_at
    append_change(db, user.id, "attachment", "delete", row.id, deleted_meta={"deletedAt": row.deleted_at.isoformat()})
    db.commit()
    return {"message": "Deleted"}
