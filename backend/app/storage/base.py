from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


@dataclass
class UploadDescriptor:
    method: str
    upload_url: str
    headers: dict[str, str]


class StorageBackend(Protocol):
    def make_upload_descriptor(self, remote_key: str, mime_type: str, attachment_id: str) -> UploadDescriptor:
        ...

    def make_download_url(self, remote_key: str) -> str | None:
        ...

    def delete(self, remote_key: str) -> None:
        ...

    def save_bytes(self, remote_key: str, data: bytes, mime_type: str) -> None:
        ...

    def open_local_path(self, remote_key: str) -> str | None:
        ...
