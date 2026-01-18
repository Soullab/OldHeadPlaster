#!/bin/bash
set -e

echo "🏗️  Deploying Old Head Plaster..."

# Pull latest
git pull origin main

# Build and restart
docker compose down
docker compose build --no-cache
docker compose up -d

echo "✅ Deployed to oldhead.soullab.life"
echo ""
echo "View logs: docker compose logs -f oldhead"
