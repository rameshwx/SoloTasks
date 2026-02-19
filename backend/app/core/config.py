from __future__ import annotations

from functools import lru_cache
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = Field(default="SoloTasks API", alias="APP_NAME")
    app_env: str = Field(default="development", alias="APP_ENV")
    api_prefix: str = Field(default="/v1", alias="API_PREFIX")

    database_url: str = Field(alias="DATABASE_URL")

    jwt_secret: str = Field(alias="JWT_SECRET")
    jwt_algorithm: str = Field(default="HS256", alias="JWT_ALGORITHM")
    access_token_minutes: int = Field(default=30, alias="ACCESS_TOKEN_MINUTES")
    refresh_token_days: int = Field(default=30, alias="REFRESH_TOKEN_DAYS")

    otp_length: int = Field(default=6, alias="OTP_LENGTH")
    otp_expires_minutes: int = Field(default=10, alias="OTP_EXPIRES_MINUTES")
    otp_resend_cooldown_seconds: int = Field(default=60, alias="OTP_RESEND_COOLDOWN_SECONDS")
    otp_max_per_window: int = Field(default=5, alias="OTP_MAX_PER_WINDOW")
    otp_throttle_window_minutes: int = Field(default=30, alias="OTP_THROTTLE_WINDOW_MINUTES")
    otp_from_email: str = Field(alias="OTP_FROM_EMAIL")

    smtp_host: str = Field(alias="SMTP_HOST")
    smtp_port: int = Field(default=465, alias="SMTP_PORT")
    smtp_username: str = Field(alias="SMTP_USERNAME")
    smtp_password: str = Field(alias="SMTP_PASSWORD")
    smtp_use_tls: bool = Field(default=True, alias="SMTP_USE_TLS")

    storage_provider: str = Field(default="s3", alias="STORAGE_PROVIDER")
    storage_bucket: str = Field(default="solotasks", alias="STORAGE_BUCKET")
    storage_region: str = Field(default="us-east-1", alias="STORAGE_REGION")
    storage_s3_endpoint: str | None = Field(default=None, alias="STORAGE_S3_ENDPOINT")
    storage_s3_access_key: str | None = Field(default=None, alias="STORAGE_S3_ACCESS_KEY")
    storage_s3_secret_key: str | None = Field(default=None, alias="STORAGE_S3_SECRET_KEY")
    storage_local_root: str = Field(default="/data/storage", alias="STORAGE_LOCAL_ROOT")

    max_image_bytes: int = Field(default=20 * 1024 * 1024, alias="MAX_IMAGE_BYTES")
    max_pdf_bytes: int = Field(default=30 * 1024 * 1024, alias="MAX_PDF_BYTES")

    tombstone_retention_days: int = Field(default=30, alias="TOMBSTONE_RETENTION_DAYS")
    default_timezone: str = Field(default="UTC", alias="DEFAULT_TIMEZONE")


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[arg-type]
