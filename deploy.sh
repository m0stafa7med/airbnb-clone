#!/bin/bash
set -e

DOMAIN=${DOMAIN:-"airbnb.mostafadarwesh.com"}

echo "=== Airbnb Clone Deployment ==="

# Check if .env exists
if [ ! -f .env ]; then
    echo "ERROR: .env file not found. Copy .env.example to .env and fill in your values."
    exit 1
fi

source .env

# Step 1: Initial SSL certificate (first time only)
if [ ! -d "./certbot/conf/live/$DOMAIN" ]; then
    echo ">>> Obtaining SSL certificate for $DOMAIN..."

    # Start nginx with HTTP-only config for ACME challenge
    mkdir -p certbot/conf certbot/www

    # Create temporary nginx config (HTTP only)
    cat > nginx/nginx-init.conf << 'INITEOF'
server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 200 'Setting up SSL...';
        add_header Content-Type text/plain;
    }
}
INITEOF
    sed -i.bak "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" nginx/nginx-init.conf && rm -f nginx/nginx-init.conf.bak

    # Start nginx with init config
    docker compose -f docker-compose.prod.yml run -d --name nginx-init \
        -v "$(pwd)/nginx/nginx-init.conf:/etc/nginx/conf.d/default.conf:ro" \
        -v "$(pwd)/certbot/www:/var/www/certbot:ro" \
        -p 80:80 \
        nginx

    # Get certificate
    docker run --rm \
        -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
        -v "$(pwd)/certbot/www:/var/www/certbot" \
        certbot/certbot certonly --webroot \
        --webroot-path=/var/www/certbot \
        --email "admin@$DOMAIN" \
        --agree-tos --no-eff-email \
        -d "$DOMAIN"

    # Stop init nginx
    docker stop nginx-init && docker rm nginx-init
    rm -f nginx/nginx-init.conf

    echo ">>> SSL certificate obtained!"
fi

# Step 2: Update nginx config with actual domain
sed -i.bak "s/airbnb.mostafadarwesh.com/$DOMAIN/g" nginx/nginx.conf && rm -f nginx/nginx.conf.bak

# Step 3: Build and start all services
echo ">>> Building and starting services..."
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d

echo ""
echo "=== Deployment complete! ==="
echo "Your app is running at: https://$DOMAIN"
echo ""
echo "Useful commands:"
echo "  docker compose -f docker-compose.prod.yml logs -f     # View logs"
echo "  docker compose -f docker-compose.prod.yml down         # Stop all"
echo "  docker compose -f docker-compose.prod.yml up -d --build  # Rebuild & restart"
