#!/bin/bash
# CortexIA Platform Installation Script
# This script automates the complete deployment of CortexIA platform

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo "=================================="
echo "  CortexIA Platform Installer"
echo "  Version: 1.0"
echo "=================================="
echo ""

# 1. Check Prerequisites
log_info "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker Desktop first."
    exit 1
fi
log_success "Docker found: $(docker --version)"

if ! command -v docker compose &> /dev/null; then
    log_error "Docker Compose is not installed."
    exit 1
fi
log_success "Docker Compose found"

if ! command -v make &> /dev/null; then
    log_warning "Make is not installed. You can still use docker compose commands directly."
fi

# 2. Check if we're in the right directory
if [ ! -f "docker/docker-compose.yml" ]; then
    log_error "Please run this script from the CortexIA project root directory"
    exit 1
fi
log_success "Running from correct directory"

# 3. Load environment variables
log_info "Loading environment variables..."
if [ -f "environments/local/.env" ]; then
    source environments/local/.env
    log_success "Environment file loaded"
else
    log_warning ".env file not found, using defaults"
fi

# 4. Create necessary directories
log_info "Creating necessary directories..."
mkdir -p foundation/orchestration/app
mkdir -p foundation/rag/app
mkdir -p scripts
mkdir -p examples
log_success "Directories created"

# 5. Stop any existing containers
log_info "Stopping existing containers (if any)..."
cd docker
docker compose down 2>/dev/null || true
log_success "Existing containers stopped"

# 6. Pull all Docker images
log_info "Pulling Docker images (this may take a while)..."
docker compose pull
log_success "Docker images pulled"

# 7. Start core infrastructure (Foundation + Storage)
log_info "Starting core infrastructure..."
docker compose up -d cortexia-postgres cortexia-minio cortexia-qdrant cortexia-neo4j
sleep 10  # Wait for databases to initialize
log_success "Core infrastructure started"

# 8. Create databases in Postgres
log_info "Creating databases in Postgres..."
POSTGRES_USER=${POSTGRES_USER:-cortexia}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-cortexia123}

# Wait for Postgres to be ready
log_info "Waiting for Postgres to be ready..."
for i in {1..30}; do
    if docker exec cortexia-postgres pg_isready -U $POSTGRES_USER &> /dev/null; then
        log_success "Postgres is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "Postgres failed to start"
        exit 1
    fi
    sleep 2
done

# Create databases
log_info "Creating application databases..."
docker exec cortexia-postgres psql -U $POSTGRES_USER -d postgres -c "CREATE DATABASE IF NOT EXISTS kong;" 2>/dev/null || \
docker exec cortexia-postgres psql -U $POSTGRES_USER -d postgres -c "SELECT 'kong database already exists';" &> /dev/null

docker exec cortexia-postgres psql -U $POSTGRES_USER -d postgres -c "CREATE DATABASE IF NOT EXISTS opik;" 2>/dev/null || true
docker exec cortexia-postgres psql -U $POSTGRES_USER -d postgres -c "CREATE DATABASE IF NOT EXISTS openmetadata_db;" 2>/dev/null || true

log_success "Databases created"

# 9. Start security layer
log_info "Starting security services..."
docker compose up -d cortexia-vault cortexia-opa
sleep 5
log_success "Security services started"

# 10. Start observability
log_info "Starting observability stack..."
docker compose up -d cortexia-prometheus cortexia-grafana
log_success "Observability stack started"

# 11. Start model serving
log_info "Starting model serving..."
docker compose up -d cortexia-ollama cortexia-litellm
sleep 10  # Wait for Ollama to start
log_success "Model serving started"

# 12. Download Ollama model
log_info "Downloading TinyLlama model (this may take a few minutes)..."
docker exec cortexia-ollama ollama pull tinyllama
log_success "TinyLlama model downloaded"

# 13. Start MLflow
log_info "Building and starting MLflow..."
docker compose up -d cortexia-mlflow
sleep 5
log_success "MLflow started"

# 14. Start Agent Registry
log_info "Starting Agent Registry..."
docker compose up -d cortexia-registry
sleep 5
log_success "Agent Registry started"

# 15. Build and start Agent Orchestrator
log_info "Building Agent Orchestrator..."
docker compose up -d --build cortexia-orchestrator
sleep 10
log_success "Agent Orchestrator started"

# 16. Build and start RAG Pipeline
log_info "Building RAG Pipeline..."
docker compose up -d --build cortexia-rag
sleep 10
log_success "RAG Pipeline started"

# 16.5 Build and start MCP Gateway
log_info "Building MCP Gateway..."
docker compose up -d --build cortexia-mcp-gateway
sleep 5
log_success "MCP Gateway started"

# 16.6 Start AI Platform Foundation (JupyterLab)
log_info "Starting AI Platform Foundation (JupyterLab)..."
docker compose up -d cortexia-jupyter
log_success "AI Platform started"

# 16.7 Start UI Platform (Flowise & Backstage)
log_info "Starting UI Platform (Flowise & Backstage)..."
docker compose up -d cortexia-flowise cortexia-backstage
log_success "UI Platform started"

# 16.8 Start Governance Layer (Phase 6)
log_info "Starting Governance Layer (Opik & OpenMetadata)..."
# Note: OpenMetadata is heavy, consider commenting out if low on RAM
docker compose up -d cortexia-opik-redis cortexia-opik-backend cortexia-opik-frontend
# docker compose up -d cortexia-governance-search cortexia-openmetadata
log_success "Governance services started"

# 17. Start Kong Gateway
log_info "Initializing Kong Gateway..."
docker compose up -d cortexia-kong-migrations
sleep 15  # Wait for migrations to complete

docker compose up -d cortexia-kong
sleep 10
log_success "Kong Gateway started"

# 18. Configure Kong routes
log_info "Configuring Kong routes..."
cd ..
bash scripts/configure-kong.sh
log_success "Kong routes configured"

# 20. Start Kafka and Kafka-UI
log_info "Starting Kafka event backbone..."
docker compose up -d cortexia-kafka
sleep 15  # Kafka takes time to start

docker compose up -d cortexia-kafka-ui
sleep 5
log_success "Kafka services started"

# 21. Start Nginx Reverse Proxy
log_info "Starting Nginx reverse proxy..."
docker compose up -d cortexia-proxy
sleep 5
log_success "Nginx started"

# 22. Verify all services
log_info "Verifying services..."
cd ..

# Check critical services
FAILED=0

if ! curl -s http://localhost:8088/agents/health | grep -q "ok"; then
    log_warning "Agent Orchestrator health check failed"
    FAILED=$((FAILED + 1))
else
    log_success "Agent Orchestrator is healthy"
fi

if ! curl -s http://localhost:8088/rag/health | grep -q "ok"; then
    log_warning "RAG Pipeline health check failed"
    FAILED=$((FAILED + 1))
else
    log_success "RAG Pipeline is healthy"
fi

if ! curl -s http://localhost:8001/ | grep -q "version"; then
    log_warning "Kong Admin API is not responding"
    FAILED=$((FAILED + 1))
else
    log_success "Kong Admin API is healthy"
fi

if ! curl -s http://localhost:8097/health | grep -q "ok"; then
    log_warning "MCP Gateway health check failed"
    FAILED=$((FAILED + 1))
else
    log_success "MCP Gateway is healthy"
fi

if ! curl -s -I http://localhost:8888/jupyter/login | grep -q "200 OK"; then
    log_warning "AI Platform (Jupyter) is not responding"
    # Not incrementing FAILED as it might take longer to start
else
    log_success "AI Platform (Jupyter) is healthy"
fi

if ! curl -s -I http://localhost:3000 | grep -q "200 OK"; then
    log_warning "Flowise is not responding yet"
else
    log_success "Flowise is healthy"
fi

if ! curl -s -I http://localhost:8088/opik/ | grep -q "200 OK"; then
    log_warning "Opik is not responding yet"
else
    log_success "Opik is healthy"
fi

# 23. Final summary
echo ""
echo "=================================="
echo "  Installation Complete!"
echo "=================================="
echo ""
log_info "Platform Status:"
echo "  - Nginx Proxy:         http://localhost:8088"
echo "  - LiteLLM UI:          http://localhost:8088/litellm/ui/"
echo "  - MLflow:              http://localhost:8088/mlflow/"
echo "  - Agent Orchestrator:  http://localhost:8088/agents/docs"
echo "  - RAG Pipeline:        http://localhost:8088/rag/docs"
echo "  - RAG Pipeline:        http://localhost:8088/rag/docs"
echo "  - Kafka-UI:            http://localhost:8088/kafka-ui/"
echo "  - AI Platform:         http://localhost:8088/jupyter/ (Token: cortexia-secret-token)"
echo "  - Visual Designer:     http://localhost:8088/flowise/"
echo "  - Developer Portal:    http://localhost:8088/backstage/"
echo "  - MCP Gateway:         http://localhost:8097/health"
echo "  - MCP Inspector:       http://localhost:8088/mcp-inspector/"
echo "  - Grafana:             http://localhost:8088/grafana/"
echo "  - Kong Proxy (API):    http://localhost:8000"
echo ""
log_info "Kong API Routes:"
echo "  - Agent Registry:      http://localhost:8000/api/registry"
echo "  - Agent Orchestrator:  http://localhost:8000/api/agents"
echo "  - RAG Pipeline:        http://localhost:8000/api/rag"
echo "  - LiteLLM Gateway:     http://localhost:8000/api/litellm"
echo "  - MCP Gateway:         http://localhost:8000/api/mcp"
echo ""

if [ $FAILED -eq 0 ]; then
    log_success "All services are running!"
else
    log_warning "$FAILED service(s) failed health checks. Check logs with: docker compose logs [service_name]"
fi

echo ""
log_info "Next steps:"
echo "  1. Test Agent Orchestrator:"
echo "     curl -X POST http://localhost:8088/agents/run -H 'Content-Type: application/json' -d '{\"message\": \"Hello CortexIA\"}'"
echo "  3. View logs: docker compose -f docker/docker-compose.yml logs -f [service_name]"
echo "  4. Stop platform: cd docker && docker compose down"
echo ""
log_success "Installation script completed successfully!"
