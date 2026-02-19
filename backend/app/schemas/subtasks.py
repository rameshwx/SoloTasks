from __future__ import annotations

from datetime import datetime
from pydantic import BaseModel, Field


class SubtaskCreate(BaseModel):
    model_config = {"populate_by_name": True}
    id: str | None = None
    title: str
    is_done: bool = Field(default=False, alias="isDone")
    order_key: str = Field(default="a", alias="orderKey")
    note: str | None = None


class SubtaskUpdate(BaseModel):
    model_config = {"populate_by_name": True}
    title: str | None = None
    is_done: bool | None = Field(default=None, alias="isDone")
    order_key: str | None = Field(default=None, alias="orderKey")
    note: str | None = None


class SubtaskOut(BaseModel):
    id: str
    task_id: str
    title: str
    is_done: bool
    order_key: str
    note: str | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
