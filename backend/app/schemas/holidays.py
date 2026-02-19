from __future__ import annotations

from datetime import date, datetime
from pydantic import BaseModel, Field

from app.db.models import HolidayType


class HolidayCreate(BaseModel):
    model_config = {"populate_by_name": True}
    id: str | None = None
    date_local: date = Field(alias="dateLocal")
    type: HolidayType
    label: str | None = None


class HolidayUpdate(BaseModel):
    label: str | None = None


class HolidayOut(BaseModel):
    id: str
    date_local: date
    type: HolidayType
    label: str | None
    created_at: datetime
    updated_at: datetime
    deleted_at: datetime | None

    model_config = {"from_attributes": True}
