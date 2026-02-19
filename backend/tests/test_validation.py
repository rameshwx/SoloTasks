import pytest

from app.services.validation import calculate_subtask_progress, validate_task_window


def test_progress_hidden_when_no_subtasks():
    assert calculate_subtask_progress([]) is None


def test_progress_formula():
    assert calculate_subtask_progress([True, False, True]) == pytest.approx(66.666, rel=1e-2)


def test_validate_task_window_ok():
    validate_task_window(600, 660, None)
    validate_task_window(600, None, 30)


def test_validate_task_window_rejects_midnight_cross():
    with pytest.raises(ValueError):
        validate_task_window(1430, None, 20)
