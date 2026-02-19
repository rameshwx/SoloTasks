# VPS Deployment (Ubuntu 25.04)

## 1) Install Docker

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

## 2) Deploy

```bash
git clone https://github.com/rameshwx/SoloTasks.git
cd SoloTasks/backend
cp .env.example .env
# fill secrets

docker compose up -d --build
```

## 3) TLS

Place API behind Caddy/Nginx and terminate TLS. Keep MinIO internal/private unless explicitly exposed with TLS and auth.
