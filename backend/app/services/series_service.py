from __future__ import annotations

from datetime import timedelta
import uuid

from app.db.models import Task
from app.schemas.tasks import TaskSeriesCreate


def build_series_tasks(user_id: str, payload: TaskSeriesCreate) -> tuple[str, list[Task]]:
    if payload.end_date:
        days = (payload.end_date - payload.start_date).days + 1
    else:
        assert payload.number_of_days is not None
        days = payload.number_of_days

    series_id = str(uuid.uuid4())
    tasks: list[Task] = []
    for idx in range(days):
        day = payload.start_date + timedelta(days=idx)
        tasks.append(
            Task(
                user_id=user_id,
                title=payload.base_title,
                description=payload.description,
                status=payload.status,
                date_local=day,
                start_min=payload.start_min,
                end_min=payload.end_min,
                duration_min=payload.duration_min,
                series_id=series_id,
                series_index=idx + 1,
                series_total=days,
            )
        )
    return series_id, tasks
