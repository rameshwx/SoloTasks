from __future__ import annotations

from datetime import datetime
from io import StringIO
import csv

from ics import Calendar, Event
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
    cal = Calendar()
    tasks = db.query(models.Task).filter_by(user_id=user_id, deleted_at=None).all()
    for t in tasks:
        event = Event()
        event.name = t.title
        start_hour = t.start_min // 60
        start_minute = t.start_min % 60
        event.begin = f"{t.date_local.isoformat()} {start_hour:02d}:{start_minute:02d}:00"
        if t.end_min:
            end_hour = t.end_min // 60
            end_minute = t.end_min % 60
            event.end = f"{t.date_local.isoformat()} {end_hour:02d}:{end_minute:02d}:00"
        cal.events.add(event)

    if include_holidays:
        holidays = db.query(models.Holiday).filter_by(user_id=user_id, deleted_at=None).all()
        for h in holidays:
            event = Event()
            event.name = f"Holiday ({h.type.value})" if not h.label else h.label
            event.make_all_day()
            event.begin = h.date_local.isoformat()
            cal.events.add(event)

    return str(cal)


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
