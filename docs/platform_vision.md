# CortexIA Platform Vision

This document outlines the target technology stack for the CortexIA Agentic Enterprise Platform.

| Building Block | Product | Description |
| :--- | :--- | :--- |
| **Agent Framework / Standard** | [Llama Stack](https://github.com/meta-llama/llama-stack) | Standard stack for agentic platforms defining abstractions for agents, memory, tools, and safety. |
| **Visual Agent Config UI** | [Backstage](https://backstage.io) | Internal developer portal for dashboards, governance, and configuration UIs for agents/APIs. |
| **Visual Agent Designer** | [Flowise](https://github.com/FlowiseAI/Flowise) | Node-based visual designer for creating agents, flows, and prompts. |
| **Agent Orchestration** | [LangGraph](https://github.com/langchain-ai/langgraph) | State-aware orchestration framework for complex agent workflows. |
| **Event Backbone** | [Apache Kafka](https://kafka.apache.org) | Distributed messaging for Agent-to-Agent (A2A) communication and decoupling. |
| **Agent Runtime** | [FastAPI](https://fastapi.tiangolo.com) | Lightweight, high-performance runtime for exposing agents as services. |
| **Model Serving** | [vLLM](https://github.com/vllm-project/vllm) | High-performance LLM inference server. |
| **Model Gateway** | [LiteLLM](https://github.com/BerriAI/litellm) | Unified proxy for routing calls to multiple on-prem/cloud LLMs. |
| **LLMOps** | [MLflow](https://mlflow.org) | Model lifecycle management (experiments, registry, deployment). |
| **Local LLM Mgmt** | [llmd](https://github.com/llm-d) | Daemon for managing local LLM execution. |
| **MCP Gateway** | [MCP](https://github.com/modelcontextprotocol) | Standard protocol for connecting agents with tools and data. |
| **API / Agent Gateway** | [Kong](https://konghq.com/kong-open-source) | API Gateway for security, rate limiting, and traffic control. |
| **Vector Memory** | [Qdrant](https://qdrant.tech) | Semantic memory and RAG storage. |
| **Graph Memory** | [Neo4j](https://neo4j.com) | Knowledge graph for relationships and context. |
| **Object Storage** | [MinIO](https://min.io) | S3-compatible storage for artifacts and logs. |
| **RAG & Ingestion** | [Haystack](https://haystack.deepset.ai) | Pipelines for data ingestion and semantic search. |
| **Foundation** | [OpenDataHub](https://opendatahub.io) | K8s-based AI/ML platform foundation. |
| **Observability** | [Prometheus](https://prometheus.io) + [Grafana](https://grafana.com) | Metrics and dashboards. |
| **Agent Tracing** | [Opik](https://github.com/comet-ml/opik) | Agent-specific tracing and evaluation. |
| **Trust & Fairness** | [TrustyAI](https://trustyai-explainability.github.io/trustyai-site) | Explainability and fairness analysis. |
| **Secrets Mgmt** | [Vault](https://www.vaultproject.io) | Secure management of secrets and credentials. |
| **Policy Engine** | [OPA](https://www.openpolicyagent.org) | Policy enforcement (AuthZ, Guardrails). |
| **Service Mesh** | [Istio](https://istio.io) | Traffic management, mTLS, and identity. |
| **Agent Governance** | [OpenMetadata](https://open-metadata.org) | Catalog and governance for agents, data, and models. |
| **DevOps / Lifecycle** | [Argo CD](https://argo-cd.readthedocs.io) | GitOps for agent deployment. |
