#!/bin/bash
# Kong Route Configuration Script
# Configures Kong Gateway to expose CortexIA services

KONG_ADMIN="http://localhost:8001"

echo "===== Configuring Kong Services and Routes ====="

# 1. Agent Registry Service
echo "Creating Agent Registry service..."
curl -s -X POST ${KONG_ADMIN}/services \
  -d "name=agent-registry" \
  -d "url=http://cortexia-registry:8090" | jq -r '.id'

echo "Creating Agent Registry route..."
curl -s -X POST ${KONG_ADMIN}/services/agent-registry/routes \
  -d "name=registry-route" \
  -d "paths[]=/api/registry" | jq -r '.id'

# 2. Agent Orchestrator Service
echo "Creating Agent Orchestrator service..."
curl -s -X POST ${KONG_ADMIN}/services \
  -d "name=agent-orchestrator" \
  -d "url=http://cortexia-orchestrator:8095" | jq -r '.id'

echo "Creating Agent Orchestrator route..."
curl -s -X POST ${KONG_ADMIN}/services/agent-orchestrator/routes \
  -d "name=orchestrator-route" \
  -d "paths[]=/api/agents" | jq -r '.id'

# 3. RAG Pipeline Service
echo "Creating RAG Pipeline service..."
curl -s -X POST ${KONG_ADMIN}/services \
  -d "name=rag-pipeline" \
  -d "url=http://cortexia-rag:8096" | jq -r '.id'

echo "Creating RAG Pipeline route..."
curl -s -X POST ${KONG_ADMIN}/services/rag-pipeline/routes \
  -d "name=rag-route" \
  -d "paths[]=/api/rag" | jq -r '.id'

# 4. LiteLLM Gateway Service
echo "Creating LiteLLM service..."
curl -s -X POST ${KONG_ADMIN}/services \
  -d "name=litellm-gateway" \
  -d "url=http://cortexia-litellm:4000" | jq -r '.id'

echo "Creating LiteLLM route..."
curl -s -X POST ${KONG_ADMIN}/services/litellm-gateway/routes \
  -d "name=litellm-route" \
  -d "paths[]=/api/litellm" | jq -r '.id'

# 5. MCP Gateway Service
echo "Creating MCP Gateway service..."
curl -s -X POST ${KONG_ADMIN}/services \
  -d "name=mcp-gateway" \
  -d "url=http://cortexia-mcp-gateway:8000" | jq -r '.id'

echo "Creating MCP Gateway route..."
curl -s -X POST ${KONG_ADMIN}/services/mcp-gateway/routes \
  -d "name=mcp-route" \
  -d "paths[]=/api/mcp" | jq -r '.id'

echo ""
echo "===== Kong Configuration Complete ====="
echo "Services are now accessible via Kong Proxy (port 8000):"
echo "  - Agent Registry:     http://localhost:8000/api/registry"
echo "  - Agent Orchestrator: http://localhost:8000/api/agents"
echo "  - RAG Pipeline:       http://localhost:8000/api/rag"
echo "  - LiteLLM Gateway:    http://localhost:8000/api/litellm"
echo "  - MCP Gateway:        http://localhost:8000/api/mcp"
