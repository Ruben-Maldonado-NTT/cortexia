#!/bin/bash
# CortexIA Platform Uninstaller
# Removes all containers, volumes, and networks

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}WARNING: This will remove all CortexIA containers, volumes, and data!${NC}"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Uninstall cancelled"
    exit 0
fi

echo "Stopping and removing containers..."
cd docker
docker compose down -v --remove-orphans
# The above command cleans orphans, but being explicit often helps
# docker rm -f cortexia-mcp-gateway 2>/dev/null || true

echo "Removing Docker images (optional)..."
read -p "Remove downloaded Docker images? (yes/no): " remove_images

if [ "$remove_images" = "yes" ]; then
    docker compose down --rmi all
fi

echo -e "${RED}Uninstall complete. All data has been removed.${NC}"
