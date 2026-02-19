from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.db import models
from app.repositories.serializers import orm_to_dict
from app.schemas.sync import RejectedOp, SyncOp
from app.services.sync_log_service import append_change


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def parse_dt(value: str | None) -> datetime | None:
    if value is None:
        return None
    if value.endswith("Z"):
        value = value[:-1] + "+00:00"
    return datetime.fromisoformat(value)


def parse_date(value: str | None):
    if value is None:
        return None
    return datetime.fromisoformat(f"{value}T00:00:00+00:00").date()


class SyncService:
    def __init__(self, db: Session):
        self.db = db

    def apply_ops(self, user_id: str, ops: list[SyncOp]) -> tuple[int, list[RejectedOp]]:
        applied = 0
        rejected: list[RejectedOp] = []

        for op in ops:
            already = (
                self.db.query(models.AppliedOp)
                .filter(models.AppliedOp.user_id == user_id, models.AppliedOp.op_id == op.op_id)
                .first()
            )
            if already:
                continue

            try:
                self._apply_one(user_id=user_id, op=op)
                self.db.add(models.AppliedOp(user_id=user_id, op_id=op.op_id))
                applied += 1
            except HTTPException as exc:
                rejected.append(RejectedOp(opId=op.op_id, reason=str(exc.detail)))
            except Exception as exc:  # noqa: BLE001
                rejected.append(RejectedOp(opId=op.op_id, reason=str(exc)))

        self.db.commit()
        return applied, rejected

    def _apply_one(self, user_id: str, op: SyncOp) -> None:
        entity = op.entity.lower()
        action = op.action.lower()

        if entity == "task":
            self._task(user_id, action, op)
            return
        if entity == "subtask":
            self._subtask(user_id, action, op)
            return
        if entity == "tag":
            self._tag(user_id, action, op)
            return
        if entity == "holiday":
            self._holiday(user_id, action, op)
            return
        if entity == "reminder":
            self._reminder(user_id, action, op)
            return
        if entity == "attachment":
            self._attachment(user_id, action, op)
            return

        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Unsupported entity {entity}")

    def _task(self, user_id: str, action: str, op: SyncOp) -> None:
        row = self.db.query(models.Task).filter_by(id=op.entity_id, user_id=user_id).first()
        now = utcnow()
        if action == "delete":
            if row and row.deleted_at is None:
                row.deleted_at = now
                row.updated_at = now
                append_change(self.db, user_id, "task", "delete", row.id, deleted_meta={"deletedAt": now.isoformat()})
            return

        payload = op.payload
        if row is None:
            row = models.Task(id=op.entity_id, user_id=user_id)
            self.db.add(row)

        row.title = payload.get("title", row.title)
        row.description = payload.get("description", row.description)
        if payload.get("status"):
            row.status = models.TaskStatus(payload["status"])
        if payload.get("dateLocal"):
            row.date_local = parse_date(payload["dateLocal"])
        if payload.get("startMin") is not None:
            row.start_min = int(payload["startMin"])
        if payload.get("endMin") is not None:
            row.end_min = int(payload["endMin"])
        if payload.get("durationMin") is not None:
            row.duration_min = int(payload["durationMin"])
        row.series_id = payload.get("seriesId", row.series_id)
        row.series_index = payload.get("seriesIndex", row.series_index)
        row.series_total = payload.get("seriesTotal", row.series_total)
        row.deleted_at = None
        row.updated_at = now
        self.db.flush()
        append_change(self.db, user_id, "task", "upsert", row.id, record=orm_to_dict(row))

    def _subtask(self, user_id: str, action: str, op: SyncOp) -> None:
        row = self.db.query(models.Subtask).filter_by(id=op.entity_id, user_id=user_id).first()
        now = utcnow()
        if action == "delete":
            if row and row.deleted_at is None:
                row.deleted_at = now
                row.updated_at = now
                append_change(
                    self.db,
                    user_id,
                    "subtask",
                    "delete",
                    row.id,
                    deleted_meta={"deletedAt": now.isoformat()},
                )
            return

        payload = op.payload
        if row is None:
            row = models.Subtask(id=op.entity_id, user_id=user_id, task_id=payload["taskId"], title=payload["title"])
            self.db.add(row)

        row.title = payload.get("title", row.title)
        if payload.get("isDone") is not None:
            row.is_done = bool(payload["isDone"])
        row.order_key = payload.get("orderKey", row.order_key)
        row.note = payload.get("note", row.note)
        row.deleted_at = None
        row.updated_at = now
        self.db.flush()
        append_change(self.db, user_id, "subtask", "upsert", row.id, record=orm_to_dict(row))

    def _tag(self, user_id: str, action: str, op: SyncOp) -> None:
        row = self.db.query(models.Tag).filter_by(id=op.entity_id, user_id=user_id).first()
        now = utcnow()
        if action == "delete":
            if row and row.deleted_at is None:
                row.deleted_at = now
                row.updated_at = now
                append_change(self.db, user_id, "tag", "delete", row.id, deleted_meta={"deletedAt": now.isoformat()})
            return

        payload = op.payload
        if row is None:
            row = models.Tag(id=op.entity_id, user_id=user_id, name=payload["name"])
            self.db.add(row)

        row.name = payload.get("name", row.name)
        row.color = payload.get("color", row.color)
        row.deleted_at = None
        row.updated_at = now
        self.db.flush()
        append_change(self.db, user_id, "tag", "upsert", row.id, record=orm_to_dict(row))

    def _holiday(self, user_id: str, action: str, op: SyncOp) -> None:
        row = self.db.query(models.Holiday).filter_by(id=op.entity_id, user_id=user_id).first()
        now = utcnow()
        if action == "delete":
            if row and row.deleted_at is None:
                row.deleted_at = now
                row.updated_at = now
                append_change(
                    self.db,
                    user_id,
                    "holiday",
                    "delete",
                    row.id,
                    deleted_meta={"deletedAt": now.isoformat()},
                )
            return

        payload = op.payload
        if row is None:
            row = models.Holiday(
                id=op.entity_id,
                user_id=user_id,
                date_local=parse_date(payload["dateLocal"]),
                type=models.HolidayType(payload["type"]),
            )
            self.db.add(row)

        if payload.get("dateLocal"):
            row.date_local = parse_date(payload["dateLocal"])
        if payload.get("type"):
            row.type = models.HolidayType(payload["type"])
        row.label = payload.get("label", row.label)
        row.deleted_at = None
        row.updated_at = now
        self.db.flush()
        append_change(self.db, user_id, "holiday", "upsert", row.id, record=orm_to_dict(row))

    def _reminder(self, user_id: str, action: str, op: SyncOp) -> None:
        row = self.db.query(models.Reminder).filter_by(id=op.entity_id, user_id=user_id).first()
        now = utcnow()
        if action == "delete":
            if row and row.deleted_at is None:
                row.deleted_at = now
                row.updated_at = now
                append_change(
                    self.db,
                    user_id,
                    "reminder",
                    "delete",
                    row.id,
                    deleted_meta={"deletedAt": now.isoformat()},
                )
            return

        payload = op.payload
        if row is None:
            row = models.Reminder(
                id=op.entity_id,
                user_id=user_id,
                target_type=models.ReminderTargetType(payload["targetType"]),
                target_id=payload["targetId"],
            )
            self.db.add(row)

        if payload.get("targetType"):
            row.target_type = models.ReminderTargetType(payload["targetType"])
        row.target_id = payload.get("targetId", row.target_id)
        row.trigger_at_utc = parse_dt(payload.get("triggerAtUtc"))
        row.offset_min_from_task_start = payload.get("offsetMinFromTaskStart")
        row.deleted_at = None
        row.updated_at = now
        self.db.flush()
        append_change(self.db, user_id, "reminder", "upsert", row.id, record=orm_to_dict(row))

    def _attachment(self, user_id: str, action: str, op: SyncOp) -> None:
        row = self.db.query(models.Attachment).filter_by(id=op.entity_id, user_id=user_id).first()
        now = utcnow()
        if action == "delete":
            if row and row.deleted_at is None:
                row.deleted_at = now
                row.updated_at = now
                append_change(
                    self.db,
                    user_id,
                    "attachment",
                    "delete",
                    row.id,
                    deleted_meta={"deletedAt": now.isoformat()},
                )
            return

        payload = op.payload
        if row is None:
            row = models.Attachment(
                id=op.entity_id,
                user_id=user_id,
                task_id=payload["taskId"],
                type=models.AttachmentType(payload["type"]),
                name=payload["name"],
                size=int(payload["size"]),
                remote_key=payload["remoteKey"],
            )
            self.db.add(row)

        if payload.get("type"):
            row.type = models.AttachmentType(payload["type"])
        row.task_id = payload.get("taskId", row.task_id)
        row.name = payload.get("name", row.name)
        if payload.get("size") is not None:
            row.size = int(payload["size"])
        row.remote_key = payload.get("remoteKey", row.remote_key)
        row.cached_path = payload.get("cachedPath", row.cached_path)
        if payload.get("keepOffline") is not None:
            row.keep_offline = bool(payload["keepOffline"])
        row.deleted_at = None
        row.updated_at = now
        self.db.flush()
        append_change(self.db, user_id, "attachment", "upsert", row.id, record=orm_to_dict(row))
