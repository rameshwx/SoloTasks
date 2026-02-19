from __future__ import annotations

import csv
import io
from datetime import datetime

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from fastapi.responses import JSONResponse, PlainTextResponse
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db import models
from app.db.session import get_db
from app.schemas.export_import import ImportCsvResponse, ImportJsonResponse
from app.services.export_import_service import export_csv_tasks, export_ics, export_json_snapshot

router = APIRouter(tags=["export-import"])


@router.get("/export/json")
def export_json(db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    data = export_json_snapshot(db, user.id)
    return JSONResponse(content=data)


@router.get("/export/csv")
def export_csv(db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    return PlainTextResponse(export_csv_tasks(db, user.id), media_type="text/csv")


@router.get("/export/ics")
def export_ics_route(
    include_holidays: bool = Query(default=False, alias="includeHolidays"),
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    return PlainTextResponse(export_ics(db, user.id, include_holidays), media_type="text/calendar")


@router.post("/import/json", response_model=ImportJsonResponse)
async def import_json(
    mode: str = Query(default="replace_all"),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    if mode != "replace_all":
        raise HTTPException(status_code=400, detail="Only replace_all mode is supported")

    payload = await file.read()
    import json

    data = json.loads(payload)

    tables = [
        "task_tags",
        "reminders",
        "attachments",
        "subtasks",
        "tasks",
        "tags",
        "holidays",
        "smart_lists",
    ]
    for table in tables:
        db.execute(text(f"DELETE FROM {table} WHERE user_id = :user_id"), {"user_id": user.id})

    count = 0

    for item in data.get("tags", []):
        db.add(
            models.Tag(
                id=item["id"],
                user_id=user.id,
                name=item["name"],
                color=item.get("color"),
                deleted_at=parse_opt_dt(item.get("deleted_at")),
            )
        )
        count += 1

    for item in data.get("tasks", []):
        db.add(
            models.Task(
                id=item["id"],
                user_id=user.id,
                title=item["title"],
                description=item.get("description"),
                status=models.TaskStatus(item["status"]),
                date_local=datetime.fromisoformat(item["date_local"]).date(),
                start_min=item["start_min"],
                end_min=item.get("end_min"),
                duration_min=item.get("duration_min"),
                series_id=item.get("series_id"),
                series_index=item.get("series_index"),
                series_total=item.get("series_total"),
                deleted_at=parse_opt_dt(item.get("deleted_at")),
            )
        )
        count += 1

    for item in data.get("subtasks", []):
        db.add(
            models.Subtask(
                id=item["id"],
                user_id=user.id,
                task_id=item["task_id"],
                title=item["title"],
                is_done=item.get("is_done", False),
                order_key=item.get("order_key", "a"),
                note=item.get("note"),
                deleted_at=parse_opt_dt(item.get("deleted_at")),
            )
        )
        count += 1

    for item in data.get("holidays", []):
        db.add(
            models.Holiday(
                id=item["id"],
                user_id=user.id,
                date_local=datetime.fromisoformat(item["date_local"]).date(),
                type=models.HolidayType(item["type"]),
                label=item.get("label"),
                deleted_at=parse_opt_dt(item.get("deleted_at")),
            )
        )
        count += 1

    db.commit()
    return ImportJsonResponse(importedCount=count)


@router.post("/import/csv", response_model=ImportCsvResponse)
async def import_csv(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    content = (await file.read()).decode("utf-8")
    reader = csv.DictReader(io.StringIO(content))

    count = 0
    for row in reader:
        task = models.Task(
            user_id=user.id,
            title=row["title"],
            date_local=datetime.fromisoformat(row["dateLocal"]).date(),
            start_min=int(row["startMin"]),
            end_min=int(row["endMin"]),
            status=models.TaskStatus.todo,
        )
        db.add(task)
        count += 1

    db.commit()
    return ImportCsvResponse(importedCount=count)


def parse_opt_dt(value: str | None):
    if not value:
        return None
    if value.endswith("Z"):
        value = value[:-1] + "+00:00"
    return datetime.fromisoformat(value)
