# Architecture

## Overview

SoloTasks follows a local-first, offline-first architecture:

- Flutter + Drift local database is the immediate source of truth on device.
- Mutations are persisted locally and queued to `outbox_ops`.
- Sync engine pushes ops to backend and pulls change feed via cursor.

## Backend

- FastAPI REST API (`/v1/*`)
- PostgreSQL for persistence
- Sync change log table (`sync_changes`) for cursor-based pull
- OTP authentication via SMTP
- JWT access tokens + refresh token sessions
- Attachment storage adapter:
  - S3-compatible (MinIO default)
  - Local filesystem fallback

## Conflict Resolution

- Scalars: server LWW by server timestamp
- Subtasks: merge by per-row `updated_at`, keep latest `order_key`
- Deletes win over updates
- Tombstones retained for 30 days for propagation, then purged

## Holidays

- Holidays are represented as per-date per-type records
- Multiple types can exist on same date (separate rows)
- Sync merge key: `(user_id, date_local, type)`
