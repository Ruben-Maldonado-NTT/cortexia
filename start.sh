#!/bin/bash

# CortexIA: Unified Startup Script for Kubernetes (Minikube)
# This script orchestrates the environment verification and deployment.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}   CortexIA: Kubernetes Platform Startup       ${NC}"
echo -e "${BLUE}===============================================${NC}"

# 1. Check Minikube Status
if ! command -v minikube &> /dev/null; then
    echo -e "${RED}[ERROR] minikube is not installed.${NC}"
    exit 1
fi

MINIKUBE_STATUS=$(minikube status --format '{{.Host}}' 2>/dev/null || echo "Stopped")

if [[ "$MINIKUBE_STATUS" != "Running" ]]; then
    echo -e "${YELLOW}[WARN] Minikube is not running.${NC}"
    echo -e "${BLUE}[INFO] Recommended startup: minikube start --cpus 8 --memory 12288 --addons=ingress${NC}"
    read -p "Do you want me to start minikube for you? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        minikube start --cpus 8 --memory 12288 --addons=ingress
    else
        echo -e "${RED}[ABORT] Please start minikube and try again.${NC}"
        exit 1
    fi
fi

# 2. Check Tunnel (macOS/Docker Driver requirement)
echo -e "${BLUE}[INFO] Checking if 'minikube tunnel' is required...${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! pgrep -f "minikube tunnel" > /dev/null; then
        echo -e "${YELLOW}[IMPORTANT] 'minikube tunnel' is NOT running.${NC}"
        echo -e "On macOS with Docker driver, this is REQUIRED to access the Ingress."
        echo -e "${BLUE}Please run 'sudo minikube tunnel' in a separate terminal.${NC}"
        read -p "Have you started the tunnel? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}[WARN] Continuing, but access via .localhost might fail.${NC}"
        fi
    fi
fi

# 3. Deploy Platform Layers
echo -e "${BLUE}[INFO] Starting deployment sequence...${NC}"
bash scripts/deploy_k8s.sh

# 4. Final Verification
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}       CortexIA Platform is Starting!          ${NC}"
echo -e "${GREEN}===============================================${NC}"
echo -e "Access points:"
echo -e "- Flowise:    http://flowise.localhost"
echo -e "- Backstage:  http://backstage.localhost"
echo -e "- LiteLLM UI: http://litellm.localhost/ui"
echo -e "- Opik:       http://opik.localhost"
echo -e ""
echo -e "Run 'kubectl get pods -n cortexia' to monitor progress."
