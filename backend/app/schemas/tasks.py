from __future__ import annotations

from datetime import date, datetime
from pydantic import BaseModel, Field, model_validator

from app.db.models import TaskStatus


class TaskBase(BaseModel):
    model_config = {"populate_by_name": True}
    title: str
    description: str | None = None
    status: TaskStatus = TaskStatus.todo
    date_local: date = Field(alias="dateLocal")
    start_min: int = Field(alias="startMin")
    end_min: int | None = Field(default=None, alias="endMin")
    duration_min: int | None = Field(default=None, alias="durationMin")
    series_id: str | None = Field(default=None, alias="seriesId")
    series_index: int | None = Field(default=None, alias="seriesIndex")
    series_total: int | None = Field(default=None, alias="seriesTotal")

    @model_validator(mode="after")
    def validate_window(self):
        if self.end_min is None and self.duration_min is None:
            raise ValueError("Either endMin or durationMin is required")
        if self.end_min is not None:
            if not (self.start_min < self.end_min <= 1440):
                raise ValueError("Invalid endMin")
        if self.duration_min is not None:
            if self.duration_min <= 0 or self.start_min + self.duration_min > 1440:
                raise ValueError("Invalid durationMin")
        if self.start_min < 0 or self.start_min >= 1440:
            raise ValueError("Invalid startMin")
        return self


class TaskCreate(TaskBase):
    id: str | None = None


class TaskUpdate(BaseModel):
    model_config = {"populate_by_name": True}
    title: str | None = None
    description: str | None = None
    status: TaskStatus | None = None
    date_local: date | None = Field(default=None, alias="dateLocal")
    start_min: int | None = Field(default=None, alias="startMin")
    end_min: int | None = Field(default=None, alias="endMin")
    duration_min: int | None = Field(default=None, alias="durationMin")


class TaskOut(BaseModel):
    id: str
    title: str
    description: str | None
    status: TaskStatus
    date_local: date
    start_min: int
    end_min: int | None
    duration_min: int | None
    series_id: str | None
    series_index: int | None
    series_total: int | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class TaskSeriesCreate(BaseModel):
    model_config = {"populate_by_name": True}
    base_title: str = Field(alias="baseTitle")
    description: str | None = None
    status: TaskStatus = TaskStatus.todo
    start_date: date = Field(alias="startDate")
    end_date: date | None = Field(default=None, alias="endDate")
    number_of_days: int | None = Field(default=None, alias="numberOfDays")
    start_min: int = Field(alias="startMin")
    end_min: int | None = Field(default=None, alias="endMin")
    duration_min: int | None = Field(default=None, alias="durationMin")

    @model_validator(mode="after")
    def validate_series(self):
        if self.end_date is None and self.number_of_days is None:
            raise ValueError("Provide endDate or numberOfDays")
        if self.end_date is not None and self.end_date < self.start_date:
            raise ValueError("Invalid date range")
        return self


class TaskSeriesCreateResponse(BaseModel):
    model_config = {"populate_by_name": True}
    series_id: str = Field(alias="seriesId")
    total: int
    tasks: list[TaskOut]
