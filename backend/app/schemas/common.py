from __future__ import annotations

from datetime import datetime
from pydantic import BaseModel


class ApiMessage(BaseModel):
    message: str


class PaginationMeta(BaseModel):
    cursor: int | None = None
    server_time: datetime
