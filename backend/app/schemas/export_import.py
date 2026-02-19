from __future__ import annotations

from pydantic import BaseModel, Field


class ImportJsonResponse(BaseModel):
    model_config = {"populate_by_name": True}
    imported_count: int = Field(alias="importedCount")


class ImportCsvResponse(BaseModel):
    model_config = {"populate_by_name": True}
    imported_count: int = Field(alias="importedCount")
