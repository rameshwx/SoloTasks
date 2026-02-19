# SoloTasks Backend

## Run locally

```bash
cp .env.example .env
docker compose up -d --build
```

## Migrations

```bash
alembic upgrade head
```

## Tests

```bash
pip install -e .[dev]
pytest -q
```
