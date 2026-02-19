# SoloTasks Monorepo

SoloTasks is a production-oriented, calendar-first personal task manager with:

- Flutter mobile app (`mobile/`) for Android and iOS.
- FastAPI backend (`backend/`) with PostgreSQL, JWT auth, OTP email login, sync engine, and object storage.

## Locked Navigation

Bottom navigation is fixed to:

1. Today
2. Calendar
3. Tasks
4. Settings

## Quick Start

1. Backend:
   - `cd backend`
   - `cp .env.example .env`
   - `docker compose up -d --build`
2. Mobile:
   - `cd mobile`
   - `flutter pub get`
   - `flutter pub run build_runner build --delete-conflicting-outputs`
   - `flutter run`

## Repository Layout

- `backend/`: API, migrations, tests, docker setup.
- `mobile/`: Flutter app with local-first architecture.
- `docs/`: Architecture, sync protocol, deployment, OpenAPI contract.

## VPS automation

- One-command bootstrap (targeting `51.255.201.31`) is available at `backend/deploy/bootstrap_51.255.201.31.sh`.
- Full deployment steps are documented in `docs/deployment-vps.md`.
