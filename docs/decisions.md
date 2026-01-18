# CortexIA Architecture Decision Records (ADRs)

## Overview
This document captures key architectural decisions made during the development of CortexIA, including context, rationale, and alternatives considered.

---

## ADR-001: Docker Compose for Local Development

**Date**: 2026-01-17  
**Status**: ✅ Accepted  
**Deciders**: Platform Team

### Context
Need a simple, reproducible way to run the entire platform locally for development and testing.

### Decision
Use Docker Compose with modular YAML files for service orchestration.

### Rationale
- **Portability**: Works on Mac, Linux, Windows
- **Simplicity**: Single `make up` command to start everything
- **Modularity**: Services grouped by layer (storage, security, models, etc.)
- **Developer Experience**: Fast iteration without K8s complexity

### Alternatives Considered
- **Kubernetes (K3s/Kind)**: Too heavy for local dev
- **Plain Docker**: Manual networking and dependencies

### Consequences
- ✅ Fast onboarding for new developers
- ✅ Easy to debug with `docker logs`
- ⚠️ Not production-ready (Phase 7 will add K8s)

---

## ADR-002: Nginx as Unified Reverse Proxy

**Date**: 2026-01-17  
**Status**: ✅ Accepted

### Context
Multiple web UIs (LiteLLM, MLflow, Grafana) need to be accessible via a single entry point.

### Decision
Deploy Nginx as reverse proxy on port 8088 with subpath routing.

### Rationale
- **Single Entry Point**: `http://localhost:8088` for all services
- **Path-Based Routing**: `/litellm/`, `/mlflow/`, `/agents/`, etc.
- **Lightweight**: Minimal resource overhead
- **Production-Ready**: Same pattern works in production

### Alternatives Considered
- **Traefik**: More complex configuration
- **Direct Port Exposure**: Poor UX (multiple ports to remember)

### Consequences
- ✅ Clean user experience
- ⚠️ Requires custom `sub_filter` rules for some apps (LiteLLM SSO)

---

## ADR-003: Shared Postgres for Multiple Services

**Date**: 2026-01-17  
**Status**: ✅ Accepted

### Context
LiteLLM, MLflow, and Kong all need relational databases.

### Decision
Use a single Postgres instance with separate databases (`litellm`, `kong`, `mlflow`).

### Rationale
- **Resource Efficiency**: One container vs. three
- **Operational Simplicity**: Single backup/restore strategy
- **Standard Practice**: Common in monorepo platforms

### Alternatives Considered
- **Separate Postgres Instances**: Higher resource usage

### Consequences
- ✅ Lower memory footprint
- ⚠️ Single point of failure (mitigated by backups)

---

## ADR-004: LiteLLM as Model Gateway

**Date**: 2026-01-17  
**Status**: ✅ Accepted

### Context
Need unified API for multiple LLM providers (Ollama, OpenAI, Azure).

### Decision
Deploy LiteLLM Proxy as the model gateway.

### Rationale
- **Unified API**: OpenAI-compatible interface for all models
- **Provider Abstraction**: Switch between Ollama, OpenAI, etc. transparently
- **Admin UI**: Built-in UI for model management
- **Cost Tracking**: Usage logging and budgets

### Alternatives Considered
- **Direct Ollama Access**: No provider abstraction
- **Custom Gateway**: Reinventing the wheel

### Consequences
- ✅ Easy to add new model providers
- ✅ Consistent API for all agents
- ⚠️ Additional network hop

---

## ADR-005: Ollama for Local Model Serving

**Date**: 2026-01-17  
**Status**: ✅ Accepted

### Context
Need local LLM inference without external API dependencies.

### Decision
Use Ollama for local model serving (initially Llama3, downgraded to TinyLlama for resource constraints).

### Rationale
- **Privacy**: All inference stays local
- **Zero Cost**: No API fees
- **Mac Optimized**: Runs well on Apple Silicon
- **Easy Model Management**: `ollama pull <model>`

### Alternatives Considered
- **vLLM**: Requires GPU, more complex setup
- **LMStudio**: GUI-based, not ideal for automation

### Consequences
- ✅ Full privacy and offline capability
- ⚠️ Limited by local hardware (switched to TinyLlama due to OOM)

---

## ADR-006: TinyLlama Instead of Llama3

**Date**: 2026-01-18  
**Status**: ✅ Accepted

### Context
Llama3 (4.7GB) caused OOM crashes on local Mac during testing.

### Decision
Switch to TinyLlama (637MB, 1.1B parameters) as the default model.

### Rationale
- **Stability**: No more OOM crashes
- **Fast Inference**: Suitable for development/testing
- **Swap later**: Easy to switch to larger models in production

### Alternatives Considered
- **External API (OpenAI)**: Adds cost and latency

### Consequences
- ✅ Reliable local development
- ⚠️ Lower quality responses (acceptable for dev/test)

---

## ADR-007: Haystack 2.x for RAG Pipeline

**Date**: 2026-01-18  
**Status**: ✅ Accepted

### Context
Need a robust RAG (Retrieval-Augmented Generation) framework.

### Decision
Use Haystack 2.x with Qdrant integration.

### Rationale
- **Modern Architecture**: Pipeline-based, composable
- **Qdrant Integration**: Native support for vector DB
- **LiteLLM Compatible**: Works with OpenAI-compatible APIs
- **Active Development**: Strong community

### Alternatives Considered
- **LangChain**: More complex, heavier dependencies
- **LlamaIndex**: Less flexible pipelines

### Consequences
- ✅ Clean separation of indexing vs. querying
- ✅ Easy to extend with custom components

---

## ADR-008: Kong Gateway with Postgres Backend

**Date**: 2026-01-18  
**Status**: ✅ Accepted

### Context
Need API Gateway for unified access, rate limiting, and future auth plugins.

### Decision
Deploy Kong Gateway in DB mode using existing Postgres instance.

### Rationale
- **Enterprise Features**: Rate limiting, auth plugins, monitoring
- **Declarative Config**: Routes defined via Admin API
- **Shared DB**: Reuses existing Postgres (separate `kong` database)
- **Production-Ready**: Same setup works at scale

### Alternatives Considered
- **DB-less Mode**: Harder to manage dynamic routes
- **Traefik**: Less feature-rich for API management

### Consequences
- ✅ Centralized API management
- ✅ Future-proof for enterprise features (RBAC, OAuth)

---

## ADR-009: Kafka in KRaft Mode (No Zookeeper)

**Date**: 2026-01-18  
**Status**: ✅ Accepted

### Context
Need event backbone for async agent communication.

### Decision
Deploy Kafka in KRaft mode (no Zookeeper dependency).

### Rationale
- **Simplified Architecture**: One less service to manage
- **Future-Proof**: Zookeeper deprecated in Kafka 4.x
- **Lower Resource Usage**: Fewer containers
- **Modern Best Practice**: KRaft is production-ready

### Alternatives Considered
- **Kafka + Zookeeper**: Legacy approach
- **Redis Streams**: Less mature for event sourcing

### Consequences
- ✅ Simpler deployment
- ✅ Aligned with Kafka roadmap

---

## ADR-010: LangGraph for Agent Orchestration

**Date**: 2026-01-18  
**Status**: ✅ Accepted

### Context
Need stateful, multi-step agent workflows.

### Decision
Use LangGraph with Postgres checkpointing.

### Rationale
- **State Persistence**: Postgres backend for resumable workflows
- **Flexible Graphs**: Define complex agent interactions
- **LangChain Integration**: Compatible with existing tooling

### Alternatives Considered
- **Pure LangChain**: Less control over state
- **Custom Framework**: Reinventing the wheel

### Consequences
- ✅ Resumable agent workflows
- ✅ Easy to visualize agent graphs

---

## Summary Table

| ADR | Decision                   | Status | Date       |
| --- | -------------------------- | ------ | ---------- |
| 001 | Docker Compose             | ✅      | 2026-01-17 |
| 002 | Nginx Reverse Proxy        | ✅      | 2026-01-17 |
| 003 | Shared Postgres            | ✅      | 2026-01-17 |
| 004 | LiteLLM Gateway            | ✅      | 2026-01-17 |
| 005 | Ollama for Local Inference | ✅      | 2026-01-17 |
| 006 | TinyLlama Model            | ✅      | 2026-01-18 |
| 007 | Haystack 2.x for RAG       | ✅      | 2026-01-18 |
| 008 | Kong Gateway (Postgres)    | ✅      | 2026-01-18 |
| 009 | Kafka (KRaft Mode)         | ✅      | 2026-01-18 |
| 010 | LangGraph Orchestration    | ✅      | 2026-01-18 |
