from datetime import date

from app.schemas.tasks import TaskSeriesCreate
from app.services.series_service import build_series_tasks


def test_series_generation_date_range():
    payload = TaskSeriesCreate(
        baseTitle="Focus Block",
        startDate=date(2026, 2, 1),
        endDate=date(2026, 2, 3),
        startMin=540,
        endMin=600,
    )
    series_id, tasks = build_series_tasks("user-1", payload)
    assert series_id
    assert len(tasks) == 3
    assert tasks[0].series_index == 1
    assert tasks[-1].series_index == 3
