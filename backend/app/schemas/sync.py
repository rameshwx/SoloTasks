from __future__ import annotations

from datetime import datetime
from pydantic import BaseModel, Field


class SyncOp(BaseModel):
    model_config = {"populate_by_name": True}
    op_id: str = Field(alias="opId")
    entity: str
    action: str
    entity_id: str = Field(alias="entityId")
    payload: dict = {}
    client_ts: datetime = Field(alias="clientTs")


class SyncPushInput(BaseModel):
    model_config = {"populate_by_name": True}
    device_id: str = Field(alias="deviceId")
    ops: list[SyncOp]


class RejectedOp(BaseModel):
    model_config = {"populate_by_name": True}
    op_id: str = Field(alias="opId")
    reason: str


class SyncPushResponse(BaseModel):
    model_config = {"populate_by_name": True}
    server_time: datetime = Field(alias="serverTime")
    applied_count: int = Field(alias="appliedCount")
    rejected_ops: list[RejectedOp] = Field(alias="rejectedOps")


class ChangeOut(BaseModel):
    model_config = {"populate_by_name": True}
    seq: int
    entity: str
    action: str
    entity_id: str = Field(alias="entityId")
    record: dict | None = None
    deleted_meta: dict | None = Field(default=None, alias="deletedMeta")


class SyncPullResponse(BaseModel):
    model_config = {"populate_by_name": True}
    cursor: int
    server_time: datetime = Field(alias="serverTime")
    changes: list[ChangeOut]
