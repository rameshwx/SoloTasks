#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

VPS_HOST="${VPS_HOST:-51.255.201.31}"
VPS_PORT="${VPS_PORT:-22}"
VPS_USER="${VPS_USER:-ubuntu}"
REPO_URL="${REPO_URL:-https://github.com/rameshwx/SoloTasks.git}"
BRANCH="${BRANCH:-main}"
APP_DIR="${APP_DIR:-/opt/SoloTasks}"
API_DOMAIN="${API_DOMAIN:-}"
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-}"
BACKEND_ENV_FILE="${BACKEND_ENV_FILE:-${ROOT_DIR}/backend/.env}"

if [[ -z "${API_DOMAIN}" ]]; then
  echo "Set API_DOMAIN, e.g. API_DOMAIN=api.solotasks.example.com"
  exit 1
fi

if [[ -z "${LETSENCRYPT_EMAIL}" ]]; then
  echo "Set LETSENCRYPT_EMAIL for TLS certificate registration."
  exit 1
fi

ssh_opts=(-p "${VPS_PORT}" -o StrictHostKeyChecking=accept-new)
ssh_cmd=(ssh "${ssh_opts[@]}" "${VPS_USER}@${VPS_HOST}")
scp_cmd=(scp "${ssh_opts[@]}")

if [[ -n "${VPS_PASSWORD:-}" ]]; then
  if ! command -v sshpass >/dev/null 2>&1; then
    echo "VPS_PASSWORD is set but sshpass is not installed."
    echo "Install sshpass or use SSH keys."
    exit 1
  fi
  ssh_cmd=(sshpass -p "${VPS_PASSWORD}" ssh "${ssh_opts[@]}" "${VPS_USER}@${VPS_HOST}")
  scp_cmd=(sshpass -p "${VPS_PASSWORD}" scp "${ssh_opts[@]}")
fi

remote_script="/tmp/solotasks_install_and_deploy.sh"

"${scp_cmd[@]}" "${ROOT_DIR}/backend/deploy/remote/install_and_deploy.sh" "${VPS_USER}@${VPS_HOST}:${remote_script}"
"${ssh_cmd[@]}" "chmod +x ${remote_script}"

backend_env_b64=""
if [[ -f "${BACKEND_ENV_FILE}" ]]; then
  backend_env_b64="$(base64 < "${BACKEND_ENV_FILE}" | tr -d '\n')"
fi

"${ssh_cmd[@]}" \
  "APP_DIR='${APP_DIR}' \
   REPO_URL='${REPO_URL}' \
   BRANCH='${BRANCH}' \
   API_DOMAIN='${API_DOMAIN}' \
   LETSENCRYPT_EMAIL='${LETSENCRYPT_EMAIL}' \
   BACKEND_ENV_B64='${backend_env_b64}' \
   ${remote_script}"

echo "Bootstrap completed for ${VPS_HOST}."
echo "Health check URL: https://${API_DOMAIN}/health"
