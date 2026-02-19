from __future__ import annotations

from datetime import datetime, time, timedelta
from io import StringIO
import csv

from sqlalchemy.orm import Session

from app.db import models


def export_json_snapshot(db: Session, user_id: str) -> dict:
    return {
        "exportedAt": datetime.utcnow().isoformat() + "Z",
        "tasks": [to_dict(x) for x in db.query(models.Task).filter_by(user_id=user_id).all()],
        "subtasks": [to_dict(x) for x in db.query(models.Subtask).filter_by(user_id=user_id).all()],
        "tags": [to_dict(x) for x in db.query(models.Tag).filter_by(user_id=user_id).all()],
        "taskTags": [to_dict(x) for x in db.query(models.TaskTag).filter_by(user_id=user_id).all()],
        "reminders": [to_dict(x) for x in db.query(models.Reminder).filter_by(user_id=user_id).all()],
        "attachments": [to_dict(x) for x in db.query(models.Attachment).filter_by(user_id=user_id).all()],
        "holidays": [to_dict(x) for x in db.query(models.Holiday).filter_by(user_id=user_id).all()],
        "smartLists": [to_dict(x) for x in db.query(models.SmartList).filter_by(user_id=user_id).all()],
    }


def export_csv_tasks(db: Session, user_id: str) -> str:
    output = StringIO()
    writer = csv.writer(output)
    writer.writerow(["id", "title", "dateLocal", "startMin", "endMin", "status"])
    for task in db.query(models.Task).filter_by(user_id=user_id, deleted_at=None).all():
        writer.writerow([task.id, task.title, task.date_local.isoformat(), task.start_min, task.end_min, task.status.value])
    return output.getvalue()


def export_ics(db: Session, user_id: str, include_holidays: bool) -> str:
    dtstamp = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    lines = [
        "BEGIN:VCALENDAR",
        "VERSION:2.0",
        "PRODID:-//SoloTasks//EN",
        "CALSCALE:GREGORIAN",
        "METHOD:PUBLISH",
    ]

    tasks = db.query(models.Task).filter_by(user_id=user_id, deleted_at=None).all()
    for t in tasks:
        lines.extend(_task_event_lines(t, dtstamp))

    if include_holidays:
        holidays = db.query(models.Holiday).filter_by(user_id=user_id, deleted_at=None).all()
        for h in holidays:
            lines.extend(_holiday_event_lines(h, dtstamp))

    lines.append("END:VCALENDAR")
    return "\r\n".join(lines) + "\r\n"


def to_dict(obj) -> dict:
    data = {}
    for col in obj.__table__.columns:  # type: ignore[attr-defined]
        value = getattr(obj, col.name)
        if isinstance(value, datetime):
            value = value.isoformat()
        elif hasattr(value, "isoformat"):
            value = value.isoformat()
        elif hasattr(value, "value"):
            value = value.value
        data[col.name] = value
    return data


def _task_event_lines(task: models.Task, dtstamp: str) -> list[str]:
    start_dt = datetime.combine(task.date_local, time(hour=task.start_min // 60, minute=task.start_min % 60))

    if task.end_min is not None:
        end_dt = datetime.combine(task.date_local, time(hour=task.end_min // 60, minute=task.end_min % 60))
    else:
        end_dt = start_dt + timedelta(minutes=task.duration_min or 0)

    lines = [
        "BEGIN:VEVENT",
        f"UID:task-{task.id}@solotasks",
        f"DTSTAMP:{dtstamp}",
        f"SUMMARY:{_ics_escape(task.title)}",
        f"DTSTART:{start_dt.strftime('%Y%m%dT%H%M%S')}",
        f"DTEND:{end_dt.strftime('%Y%m%dT%H%M%S')}",
    ]
    if task.description:
        lines.append(f"DESCRIPTION:{_ics_escape(task.description)}")
    lines.append("END:VEVENT")
    return lines


def _holiday_event_lines(holiday: models.Holiday, dtstamp: str) -> list[str]:
    summary = holiday.label or f"Holiday ({holiday.type.value})"
    day_str = holiday.date_local.strftime("%Y%m%d")
    next_day_str = (holiday.date_local + timedelta(days=1)).strftime("%Y%m%d")
    return [
        "BEGIN:VEVENT",
        f"UID:holiday-{holiday.id}@solotasks",
        f"DTSTAMP:{dtstamp}",
        f"SUMMARY:{_ics_escape(summary)}",
        f"DTSTART;VALUE=DATE:{day_str}",
        f"DTEND;VALUE=DATE:{next_day_str}",
        "END:VEVENT",
    ]


def _ics_escape(text: str) -> str:
    return (
        text.replace("\\", "\\\\")
        .replace(";", r"\;")
        .replace(",", r"\,")
        .replace("\r\n", r"\n")
        .replace("\n", r"\n")
    )
