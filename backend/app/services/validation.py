from __future__ import annotations

from typing import Iterable


def validate_task_window(start_min: int, end_min: int | None, duration_min: int | None) -> None:
    if start_min < 0 or start_min >= 1440:
        raise ValueError("startMin must be within 0..1439")
    if end_min is None and duration_min is None:
        raise ValueError("Either endMin or durationMin is required")
    if end_min is not None:
        if start_min >= end_min or end_min > 1440:
            raise ValueError("endMin is out of range")
    if duration_min is not None:
        if duration_min <= 0:
            raise ValueError("durationMin must be > 0")
        if start_min + duration_min > 1440:
            raise ValueError("Task cannot span midnight")


def calculate_subtask_progress(done_flags: Iterable[bool]) -> float | None:
    flags = list(done_flags)
    if not flags:
        return None
    done = sum(1 for x in flags if x)
    return (done / len(flags)) * 100.0
