# CortexIA Platform Architecture

## Overview
CortexIA is a multi-layered, containerized platform for building, deploying, and managing autonomous AI agents. The architecture follows a modular design with clear separation of concerns across Foundation, Security, Brain/Runtime, Control Plane, and Experience layers.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                   Experience Layer (Phase 5)                    │
│           Backstage Portal │ Flowise Visual Designer            │
└─────────────────────────────────────────────────────────────────┘
                                  │
┌─────────────────────────────────────────────────────────────────┐
│                  Control Plane (Phase 4) ✅                     │
│  ┌──────────────────────┐    ┌─────────────────────────────┐   │
│  │   Kong API Gateway   │    │  Kafka Event Backbone       │   │
│  │  - Unified Routing   │    │  - KRaft Mode (No ZK)       │   │
│  │  - Rate Limiting     │    │  - Event-Driven Patterns    │   │
│  │  - Auth Plugins      │    │  - Kafka-UI Monitoring      │   │
│  └──────────────────────┘    └─────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                  │
┌─────────────────────────────────────────────────────────────────┐
│              Brain & Runtime Layer (Phase 3) ✅                 │
│  ┌────────────────┐ ┌─────────────┐ ┌──────────────────────┐   │
│  │ Agent Registry │ │ Orchestrator│ │    RAG Pipeline      │   │
│  │  (FastAPI +    │ │ (LangGraph) │ │    (Haystack 2.x)    │   │
│  │   Qdrant)      │ │             │ │                      │   │
│  └────────────────┘ └─────────────┘ └──────────────────────┘   │
│  ┌────────────────┐ ┌─────────────┐ ┌──────────────────────┐   │
│  │ Model Gateway  │ │Model Serving│ │    MCP Gateway       │   │
│  │   (LiteLLM)    │ │  (Ollama)   │ │   (RBAC via OPA)     │   │
│  └────────────────┘ └─────────────┘ └──────────────────────┘   │
│  ┌────────────────┐                                             │
│  │      LLMOps    │                                             │
│  │     (MLflow)   │                                             │
│  └────────────────┘                                             │
└─────────────────────────────────────────────────────────────────┘
                                  │
┌─────────────────────────────────────────────────────────────────┐
│           Security & Governance Layer (Phase 2) ✅              │
│  ┌──────────────────┐ ┌─────────────────┐ ┌─────────────────┐  │
│  │ Secrets Mgmt     │ │ Policy Engine   │ │ Audit Logging   │  │
│  │ (Vault)          │ │     (OPA)       │ │  (JSON Logs)    │  │
│  └──────────────────┘ └─────────────────┘ └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                  │
┌─────────────────────────────────────────────────────────────────┐
│              Foundation Layer (Phase 1) ✅                      │
│  ┌────────────┐ ┌─────────────┐ ┌────────────┐ ┌────────────┐  │
│  │  Storage   │ │Observability│ │  Reverse   │ │  Network   │  │
│  │  - MinIO   │ │- Prometheus │ │   Proxy    │ │  - Docker  │  │
│  │  - Postgres│ │ - Grafana   │ │  (Nginx)   │ │    Net     │  │
│  │  - Qdrant  │ └─────────────┘ └────────────┘ └────────────┘  │
│  │  - Neo4j   │                                                 │
│  └────────────┘                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### Phase 1: Foundation
- **Nginx**: Reverse proxy providing unified access via `localhost:8088`
- **MinIO**: S3-compatible object storage for artifacts
- **Postgres**: Shared metadata database (LiteLLM, MLflow, Kong)
- **Qdrant**: Vector database for embeddings
- **Neo4j**: Graph database for knowledge graphs
- **Prometheus + Grafana**: Observability stack

### Phase 2: Security & Governance
- **Vault**: Secret management (dev mode with root token)
- **OPA**: Policy engine for guardrails
- **Audit**: JSON-based audit logging pattern

### Phase 3: Brain & Runtime
- **Agent Registry**: FastAPI service with Qdrant for semantic search
- **Agent Orchestrator**: LangGraph-based stateful agents (FastAPI)
- **RAG Pipeline**: Haystack 2.x with Qdrant + LiteLLM
- **Model Gateway**: LiteLLM proxy for unified LLM access
- **Model Serving**: Ollama (local inference with TinyLlama)
- **LLMOps**: MLflow for experiment tracking

### Phase 4: Control Plane
- **Kong Gateway**: API Gateway (Postgres backend)
  - Routes: `/api/registry`, `/api/agents`, `/api/rag`, `/api/litellm`
  - Admin API on port 8001, Proxy on port 8000
- **Kafka**: Event backbone (KRaft mode, no Zookeeper)
- **Kafka-UI**: Web interface for event monitoring

## Data Flow

### Agent Execution Flow
```
User Request
    │
    ├─→ Nginx (8088) ─→ Direct Service Access
    │
    └─→ Kong Proxy (8000) ─→ API Gateway Routing
            │
            ├─→ Agent Orchestrator (LangGraph)
            │       │
            │       ├─→ LiteLLM Gateway ─→ Ollama (TinyLlama)
            │       │
            │       └─→ RAG Pipeline ─→ Qdrant (Vectors) + LiteLLM
            │
            └─→ Kafka (Events) ─→ Event Consumers
```

## Network Architecture
- **Primary Network**: `cortexia-net` (bridge)
- **Entry Points**:
  - Nginx: `8088` (unified web access)
  - Kong Proxy: `8000` (API gateway)
  - Kong Admin: `8001`
- **Internal Communication**: Docker DNS resolution

## Storage Architecture
- **Volumes**:
  - `minio-data`: Object storage
  - `postgres-data`: Relational data
  - `qdrant-data`: Vector database
  - `neo4j-data`: Graph database
  - `ollama-data`: Model weights
  - `kafka-data`: Event logs

## Security Model
- **Secrets**: Managed via Vault (development mode)
- **Policies**: OPA for runtime policy enforcement
- **Authentication**: LiteLLM master key for API access
- **Network Isolation**: Docker network segmentation

## Scalability Considerations
- **Horizontal Scaling**: Kong, Kafka, and agent services are stateless
- **Vertical Scaling**: Ollama and Qdrant benefit from more RAM/GPU
- **State Management**: Postgres for persistent state, Kafka for events

## Deployment Model
- **Development**: Docker Compose (current)
- **Production**: Kubernetes (planned Phase 7)
  - Service Mesh (Istio)
  - GitOps (Argo CD)
