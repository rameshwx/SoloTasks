#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/SoloTasks}"
REPO_URL="${REPO_URL:-https://github.com/rameshwx/SoloTasks.git}"
BRANCH="${BRANCH:-main}"
API_DOMAIN="${API_DOMAIN:-}"
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-}"
BACKEND_ENV_B64="${BACKEND_ENV_B64:-}"

if [[ -z "${API_DOMAIN}" ]]; then
  echo "API_DOMAIN is required (for public TLS certificate issuance)."
  exit 1
fi

if [[ -z "${LETSENCRYPT_EMAIL}" ]]; then
  echo "LETSENCRYPT_EMAIL is required."
  exit 1
fi

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release git openssl

if ! command -v docker >/dev/null 2>&1; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

if ! command -v caddy >/dev/null 2>&1; then
  sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
    | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
    | sudo tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y caddy
fi

sudo mkdir -p "${APP_DIR}"
sudo chown -R "$USER":"$USER" "${APP_DIR}"

if [[ -d "${APP_DIR}/.git" ]]; then
  git -C "${APP_DIR}" fetch origin "${BRANCH}"
  git -C "${APP_DIR}" checkout "${BRANCH}"
  git -C "${APP_DIR}" pull --ff-only origin "${BRANCH}"
elif [[ -d "${APP_DIR}" && -n "$(ls -A "${APP_DIR}")" ]]; then
  echo "Directory ${APP_DIR} is not empty and not a git repository."
  exit 1
else
  git clone --branch "${BRANCH}" "${REPO_URL}" "${APP_DIR}"
fi

cd "${APP_DIR}/backend"

if [[ -n "${BACKEND_ENV_B64}" ]]; then
  echo "${BACKEND_ENV_B64}" | base64 --decode > .env
elif [[ ! -f .env ]]; then
  cp .env.example .env
fi

set_env() {
  local key="$1"
  local value="$2"
  local escaped
  escaped="$(printf '%s' "${value}" | sed -e 's/[\/&]/\\&/g')"
  if grep -q "^${key}=" .env; then
    sed -i "s/^${key}=.*/${key}=${escaped}/" .env
  else
    printf '%s=%s\n' "${key}" "${value}" >> .env
  fi
}

if grep -q '^JWT_SECRET=replace-with-strong-secret$' .env; then
  set_env "JWT_SECRET" "$(openssl rand -hex 32)"
fi

set_env "APP_ENV" "production"
set_env "API_PREFIX" "/v1"

for key in \
  SMTP_HOST SMTP_PORT SMTP_USERNAME SMTP_PASSWORD SMTP_USE_TLS OTP_FROM_EMAIL \
  STORAGE_PROVIDER STORAGE_BUCKET STORAGE_REGION STORAGE_S3_ENDPOINT STORAGE_S3_ACCESS_KEY STORAGE_S3_SECRET_KEY \
  STORAGE_LOCAL_ROOT DEFAULT_TIMEZONE DATABASE_URL ACCESS_TOKEN_MINUTES REFRESH_TOKEN_DAYS; do
  value="${!key:-}"
  if [[ -n "${value}" ]]; then
    set_env "${key}" "${value}"
  fi
done

tmp_service="$(mktemp)"
sed "s|__APP_DIR__|${APP_DIR}|g" "${APP_DIR}/backend/deploy/systemd/solotasks-backend.service" > "${tmp_service}"
sudo mv "${tmp_service}" /etc/systemd/system/solotasks-backend.service
sudo chmod 0644 /etc/systemd/system/solotasks-backend.service

tmp_caddy="$(mktemp)"
sed \
  -e "s|__API_DOMAIN__|${API_DOMAIN}|g" \
  -e "s|__TLS_EMAIL__|${LETSENCRYPT_EMAIL}|g" \
  "${APP_DIR}/backend/deploy/caddy/Caddyfile.template" > "${tmp_caddy}"
sudo mv "${tmp_caddy}" /etc/caddy/Caddyfile
sudo chmod 0644 /etc/caddy/Caddyfile

sudo systemctl daemon-reload
sudo systemctl enable --now docker
sudo systemctl enable --now solotasks-backend.service
sudo systemctl restart solotasks-backend.service
sudo systemctl enable --now caddy
sudo systemctl restart caddy

if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow OpenSSH >/dev/null 2>&1 || true
  sudo ufw allow 80/tcp >/dev/null 2>&1 || true
  sudo ufw allow 443/tcp >/dev/null 2>&1 || true
  sudo ufw --force enable >/dev/null 2>&1 || true
fi

echo "Deployment completed."
echo "API should be available at: https://${API_DOMAIN}/health"
