# VPS Deployment (Ubuntu 25.04)

## Automated (Recommended)

This repository now includes:
- `systemd` service template: `backend/deploy/systemd/solotasks-backend.service`
- Caddy reverse proxy + TLS template: `backend/deploy/caddy/Caddyfile.template`
- Remote install/deploy script: `backend/deploy/remote/install_and_deploy.sh`
- One-command bootstrap wrapper for your VPS: `backend/deploy/bootstrap_51.255.201.31.sh`

### Prerequisites

1. DNS `A` record for your API domain pointing to `51.255.201.31`.
2. Local `backend/.env` with production secrets (or let bootstrap create from defaults and override with env vars).
3. SSH access to the VPS user (`ubuntu`) via key or password.

### One-command bootstrap for `51.255.201.31`

From repo root:

```bash
chmod +x backend/deploy/bootstrap_51.255.201.31.sh
chmod +x backend/deploy/remote/install_and_deploy.sh

API_DOMAIN=api.yourdomain.com \
LETSENCRYPT_EMAIL=ops@yourdomain.com \
VPS_USER=ubuntu \
VPS_HOST=51.255.201.31 \
./backend/deploy/bootstrap_51.255.201.31.sh
```

If you need password-based SSH:

```bash
API_DOMAIN=api.yourdomain.com \
LETSENCRYPT_EMAIL=ops@yourdomain.com \
VPS_PASSWORD='your-ssh-password' \
./backend/deploy/bootstrap_51.255.201.31.sh
```

Notes:
- If `backend/.env` exists locally, it is securely copied to the VPS during bootstrap.
- If not, remote bootstrap creates `.env` from `.env.example` and generates `JWT_SECRET` automatically.
- The bootstrap configures and starts:
  - Docker Engine + Compose plugin
  - Backend stack via `systemd` unit `solotasks-backend.service`
  - Caddy with automatic Let's Encrypt TLS termination

### Verification

```bash
ssh ubuntu@51.255.201.31 'systemctl status solotasks-backend --no-pager'
ssh ubuntu@51.255.201.31 'systemctl status caddy --no-pager'
curl -I https://api.yourdomain.com/health
```

## Manual fallback

If automation is unavailable, you can still deploy manually:

```bash
git clone https://github.com/rameshwx/SoloTasks.git /opt/SoloTasks
cd /opt/SoloTasks/backend
cp .env.example .env
# fill secrets
docker compose up -d --build
```

Then configure Caddy/Nginx to reverse proxy to `127.0.0.1:8000`.
