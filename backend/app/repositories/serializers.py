from __future__ import annotations

from datetime import date, datetime


def orm_to_dict(model_obj) -> dict:
    data: dict = {}
    for col in model_obj.__table__.columns:  # type: ignore[attr-defined]
        value = getattr(model_obj, col.name)
        if isinstance(value, (datetime, date)):
            data[col.name] = value.isoformat()
        elif hasattr(value, "value"):
            data[col.name] = value.value
        else:
            data[col.name] = value
    return data
