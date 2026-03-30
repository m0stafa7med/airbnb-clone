#!/bin/bash
# Run this script ONCE on a fresh Ubuntu/Debian VPS to set up the server.
# Usage: bash setup-vps.sh
set -e

REPO_URL="git@github.com:m0stafa7med/airbnb-clone.git"
DEPLOY_PATH="/opt/airbnb-clone"

echo "=== VPS First-Time Setup ==="

# ── 1. Install Docker ──────────────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
    echo ">>> Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker "$USER"
    echo ">>> Docker installed."
else
    echo ">>> Docker already installed."
fi

# ── 2. Install Docker Compose plugin ──────────────────────────────────────
if ! docker compose version &>/dev/null; then
    echo ">>> Installing Docker Compose plugin..."
    apt-get install -y docker-compose-plugin
fi

# ── 3. Clone the repo ─────────────────────────────────────────────────────
if [ ! -d "$DEPLOY_PATH" ]; then
    echo ">>> Cloning repository..."
    git clone --recurse-submodules "$REPO_URL" "$DEPLOY_PATH"
else
    echo ">>> Repository already exists at $DEPLOY_PATH."
fi

cd "$DEPLOY_PATH"

# ── 4. Create .env file ───────────────────────────────────────────────────
if [ ! -f .env ]; then
    cp .env.example .env
    echo ""
    echo ">>> .env file created from template."
    echo "    IMPORTANT: Edit $DEPLOY_PATH/.env with your real values before continuing!"
    echo "    Run: nano $DEPLOY_PATH/.env"
    echo ""
    exit 0
fi

# ── 5. Replace domain in nginx config ─────────────────────────────────────
source .env
if [ -n "$DOMAIN" ] && grep -q "airbnb.mostafadarwesh.com" nginx/nginx.conf; then
    sed -i "s/airbnb.mostafadarwesh.com/$DOMAIN/g" nginx/nginx.conf
    echo ">>> Updated nginx config with domain: $DOMAIN"
fi

# ── 6. Initial deployment ─────────────────────────────────────────────────
echo ">>> Running initial deployment..."
bash deploy.sh

echo ""
echo "=== VPS setup complete! ==="
echo ""
echo "Add these GitHub Actions secrets to your repo"
echo "(Settings → Secrets → Actions → New repository secret):"
echo ""
echo "  VPS_HOST        → $(curl -s ifconfig.me 2>/dev/null || echo '<your-server-ip>')"
echo "  VPS_USER        → $USER"
echo "  VPS_SSH_KEY     → (contents of your private SSH key)"
echo "  VPS_DEPLOY_PATH → $DEPLOY_PATH"
echo ""
echo "Every push to master will now auto-deploy!"
