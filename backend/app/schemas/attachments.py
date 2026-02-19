from __future__ import annotations

from datetime import datetime
from pydantic import BaseModel, Field

from app.db.models import AttachmentType


class AttachmentCreate(BaseModel):
    model_config = {"populate_by_name": True}
    id: str | None = None
    type: AttachmentType
    name: str
    size: int
    remote_key: str = Field(alias="remoteKey")
    cached_path: str | None = Field(default=None, alias="cachedPath")
    keep_offline: bool = Field(default=False, alias="keepOffline")


class AttachmentOut(BaseModel):
    id: str
    task_id: str
    type: AttachmentType
    name: str
    size: int
    remote_key: str
    cached_path: str | None
    keep_offline: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class UploadInitInput(BaseModel):
    model_config = {"populate_by_name": True}
    task_id: str = Field(alias="taskId")
    file_name: str = Field(alias="fileName")
    mime_type: str = Field(alias="mimeType")
    size: int


class UploadInitResponse(BaseModel):
    model_config = {"populate_by_name": True}
    attachment_id: str = Field(alias="attachmentId")
    upload_url: str = Field(alias="uploadUrl")
    remote_key: str = Field(alias="remoteKey")
    method: str
    headers: dict[str, str] = {}
