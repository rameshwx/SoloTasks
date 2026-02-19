from __future__ import annotations

from pathlib import Path

from app.core.config import get_settings
from app.storage.base import StorageBackend, UploadDescriptor


class LocalStorage(StorageBackend):
    def __init__(self) -> None:
        self.settings = get_settings()
        self.root = Path(self.settings.storage_local_root)
        self.root.mkdir(parents=True, exist_ok=True)

    def _path(self, remote_key: str) -> Path:
        path = self.root / remote_key
        path.parent.mkdir(parents=True, exist_ok=True)
        return path

    def make_upload_descriptor(self, remote_key: str, mime_type: str, attachment_id: str) -> UploadDescriptor:
        return UploadDescriptor(
            method="PUT",
            upload_url=f"/v1/attachments/{attachment_id}/upload",
            headers={"Content-Type": mime_type},
        )

    def make_download_url(self, remote_key: str) -> str | None:
        return None

    def delete(self, remote_key: str) -> None:
        path = self._path(remote_key)
        if path.exists():
            path.unlink()

    def save_bytes(self, remote_key: str, data: bytes, mime_type: str) -> None:
        self._path(remote_key).write_bytes(data)

    def open_local_path(self, remote_key: str) -> str | None:
        path = self._path(remote_key)
        if not path.exists():
            return None
        return str(path)
