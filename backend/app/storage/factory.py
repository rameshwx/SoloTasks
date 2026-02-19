from __future__ import annotations

from functools import lru_cache

from app.core.config import get_settings
from app.storage.base import StorageBackend
from app.storage.local_storage import LocalStorage
from app.storage.s3_storage import S3Storage


@lru_cache
def get_storage() -> StorageBackend:
    settings = get_settings()
    if settings.storage_provider.lower() == "local":
        return LocalStorage()
    return S3Storage()
