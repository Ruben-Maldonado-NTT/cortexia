SHELL := /bin/bash

PROJECT_NAME := cortexia
COMPOSE_FILE := docker/docker-compose.yml
ENV_FILE := environments/local/.env

DC := docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE)

.PHONY: help up down restart logs status ps pull build reset health config

help:
	@echo ""
	@echo "CortexIA - Platform commands"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  up        Start platform"
	@echo "  down      Stop platform"
	@echo "  restart   Restart platform"
	@echo "  logs      Tail logs (all services)"
	@echo "  status    Show services status"
	@echo "  ps        Alias for status"
	@echo "  pull      Pull images"
	@echo "  build     Build images (if any local builds exist)"
	@echo "  reset     Stop and remove volumes (DANGEROUS: deletes data)"
	@echo "  health    Quick health checks"
	@echo "  config    Print resolved docker compose config"
	@echo ""

up:
	$(DC) up -d --remove-orphans

down:
	$(DC) down --remove-orphans

restart: down up

logs:
	$(DC) logs -f --tail=200

status:
	$(DC) ps

ps: status

pull:
	$(DC) pull

build:
	$(DC) build

reset:
	@echo "WARNING: This will delete volumes and ALL local data for CortexIA."
	@read -p "Type 'cortexia' to confirm: " confirm; \
	if [ "$$confirm" = "$(PROJECT_NAME)" ]; then \
		$(DC) down -v --remove-orphans; \
		echo "Reset completed."; \
	else \
		echo "Reset cancelled."; \
	fi

health:
	@echo "Checking CortexIA endpoints (if enabled)..."
	@echo "- Grafana:      http://localhost:$${GRAFANA_PORT:-3000}"
	@echo "- Prometheus:   http://localhost:$${PROMETHEUS_PORT:-9090}"
	@echo "- MinIO:        http://localhost:$${MINIO_PORT:-9000}"
	@echo "- MinIO Console:http://localhost:$${MINIO_CONSOLE_PORT:-9001}"
	@echo "- Qdrant:       http://localhost:$${QDRANT_PORT:-6333}"
	@echo "- Neo4j:        http://localhost:$${NEO4J_HTTP_PORT:-7474}"
	@echo ""
	@echo "Containers:"
	@$(DC) ps

config:
	$(DC) config
