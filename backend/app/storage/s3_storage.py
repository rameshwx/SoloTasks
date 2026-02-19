from __future__ import annotations

import boto3

from app.core.config import get_settings
from app.storage.base import StorageBackend, UploadDescriptor


class S3Storage(StorageBackend):
    def __init__(self) -> None:
        self.settings = get_settings()
        self.client = boto3.client(
            "s3",
            region_name=self.settings.storage_region,
            endpoint_url=self.settings.storage_s3_endpoint,
            aws_access_key_id=self.settings.storage_s3_access_key,
            aws_secret_access_key=self.settings.storage_s3_secret_key,
        )

    def make_upload_descriptor(self, remote_key: str, mime_type: str, attachment_id: str) -> UploadDescriptor:
        url = self.client.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": self.settings.storage_bucket,
                "Key": remote_key,
                "ContentType": mime_type,
            },
            ExpiresIn=600,
        )
        return UploadDescriptor(method="PUT", upload_url=url, headers={"Content-Type": mime_type})

    def make_download_url(self, remote_key: str) -> str | None:
        return self.client.generate_presigned_url(
            "get_object",
            Params={"Bucket": self.settings.storage_bucket, "Key": remote_key},
            ExpiresIn=600,
        )

    def delete(self, remote_key: str) -> None:
        self.client.delete_object(Bucket=self.settings.storage_bucket, Key=remote_key)

    def save_bytes(self, remote_key: str, data: bytes, mime_type: str) -> None:
        self.client.put_object(
            Bucket=self.settings.storage_bucket,
            Key=remote_key,
            Body=data,
            ContentType=mime_type,
        )

    def open_local_path(self, remote_key: str) -> str | None:
        return None
