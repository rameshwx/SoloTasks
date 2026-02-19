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

## VPS bootstrap (systemd + Caddy TLS)

```bash
chmod +x deploy/bootstrap_51.255.201.31.sh deploy/remote/install_and_deploy.sh
API_DOMAIN=api.yourdomain.com LETSENCRYPT_EMAIL=ops@yourdomain.com ./deploy/bootstrap_51.255.201.31.sh
```
