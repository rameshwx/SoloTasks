from __future__ import annotations

from datetime import datetime
from pydantic import BaseModel, Field, model_validator

from app.db.models import ReminderTargetType


class ReminderCreate(BaseModel):
    model_config = {"populate_by_name": True}
    id: str | None = None
    target_type: ReminderTargetType = Field(alias="targetType")
    target_id: str = Field(alias="targetId")
    trigger_at_utc: datetime | None = Field(default=None, alias="triggerAtUtc")
    offset_min_from_task_start: int | None = Field(default=None, alias="offsetMinFromTaskStart")

    @model_validator(mode="after")
    def validate_trigger(self):
        if self.trigger_at_utc is None and self.offset_min_from_task_start is None:
            raise ValueError("Provide triggerAtUtc or offsetMinFromTaskStart")
        return self


class ReminderUpdate(BaseModel):
    model_config = {"populate_by_name": True}
    trigger_at_utc: datetime | None = Field(default=None, alias="triggerAtUtc")
    offset_min_from_task_start: int | None = Field(default=None, alias="offsetMinFromTaskStart")


class ReminderOut(BaseModel):
    id: str
    target_type: ReminderTargetType
    target_id: str
    trigger_at_utc: datetime | None
    offset_min_from_task_start: int | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
