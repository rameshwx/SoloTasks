from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field, field_validator


WeekStart = Literal["sunday", "monday"]
TimeFormat = Literal["system", "12h", "24h"]


class ReminderDefaults(BaseModel):
    model_config = {"populate_by_name": True}

    default_relative_min: int = Field(default=15, alias="defaultRelativeMin", ge=1, le=1440)
    quick_options: list[int] = Field(default_factory=lambda: [5, 10, 15, 30, 60], alias="quickOptions")
    auto_create: bool = Field(default=False, alias="autoCreate")

    @field_validator("quick_options")
    @classmethod
    def validate_quick_options(cls, value: list[int]) -> list[int]:
        cleaned: list[int] = []
        for item in value:
            if item < 1 or item > 1440:
                raise ValueError("quickOptions values must be between 1 and 1440")
            if item not in cleaned:
                cleaned.append(item)
        if not cleaned:
            raise ValueError("quickOptions cannot be empty")
        return cleaned


class CalendarPrefs(BaseModel):
    model_config = {"populate_by_name": True}

    week_start: WeekStart = Field(default="sunday", alias="weekStart")
    time_format: TimeFormat = Field(default="system", alias="timeFormat")


class HolidayPrefs(BaseModel):
    model_config = {"populate_by_name": True}

    warn_when_scheduling_on_holiday: bool = Field(
        default=True, alias="warnWhenSchedulingOnHoliday"
    )
    hide_tasks_on_holidays: bool = Field(default=False, alias="hideTasksOnHolidays")


class UserPreferencesPayload(BaseModel):
    model_config = {"populate_by_name": True}

    reminder_defaults: ReminderDefaults = Field(default_factory=ReminderDefaults, alias="reminderDefaults")
    calendar_prefs: CalendarPrefs = Field(default_factory=CalendarPrefs, alias="calendarPrefs")
    holiday_prefs: HolidayPrefs = Field(default_factory=HolidayPrefs, alias="holidayPrefs")


class UserPreferencesOut(UserPreferencesPayload):
    updated_at: datetime = Field(alias="updatedAt")

