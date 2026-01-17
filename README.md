# CortexIA Platform

**CortexIA** is a modular, local-first Agentic AI Platform designed to orchestrate, govern, and observe autonomous agents. It integrates best-in-class open-source tools into a unified ecosystem for building enterprise-grade AI applications.

## 🏗 Architecture

The platform is organized into logical layers:

*   **Foundation**: Core infrastructure (Storage, Networking, Observability).
*   **Security & Governance**: Identity, Secrets, Policies, and Audit logging.
*   **Brain & Runtime**: Model serving, Model Gateway, and Agent Registry.
*   **Control Plane** (Coming Soon): API Gateway and Event Backbone.
*   **Experience** (Coming Soon): Developer Portal and UI.

## 🚀 Getting Started

### Prerequisites
*   Docker & Docker Compose
*   Make
*   Python 3.10+ (for local CLI tools)

### Installation & Running

The entire platform is containerized and managed via `docker-compose`. We use a `Makefile` to simplify common operations.

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/Ruben-Maldonado-NTT/cortexia.git
    cd cortexia
    ```

2.  **Start the Platform**:
    ```bash
    make up
    ```
    This command will pull necessary images and start all services in detached mode.

3.  **Stop the Platform**:
    ```bash
    make down
    ```

4.  **View Logs**:
    ```bash
    docker compose logs -f [service_name]
    ```

## ✅ Validation

To verify the platform is running correctly, you can run the following checks:

1.  **Check Container Status**:
    ```bash
    docker ps
    ```
    Ensure all containers (cortexia-proxy, cortexia-litellm, cortexia-mlflow, etc.) are in `Up` state.

2.  **Test Model Gateway (LiteLLM)**:
    ```bash
    curl http://localhost:8088/litellm/v1/models
    ```
    Should return a list of available models (e.g., `fake-model`, `local-llama`).

3.  **Test Local Inference (Ollama)**:
    ```bash
    docker exec cortexia-ollama ollama list
    ```
    Should show installed models (e.g., `llama3`).

## 📚 Service Catalog

The platform exposes a single entry point via **Nginx Reverse Proxy** at `http://localhost:8088`. You can also access services directly via their container ports if needed.

| Component              | Description              | Nginx Proxy URL                                                              | Direct URL                                       | User / Pass (Default)      |
| :--------------------- | :----------------------- | :--------------------------------------------------------------------------- | :----------------------------------------------- | :------------------------- |
| **Reverse Proxy**      | Unified Entry Point      | [http://localhost:8088](http://localhost:8088)                               | N/A                                              | -                          |
| **LiteLLM UI**         | Model Gateway Admin      | [http://localhost:8088/litellm/ui/](http://localhost:8088/litellm/ui/)       | [http://localhost:4000](http://localhost:4000)   | `sk-cortexia-admin-key`    |
| **MLflow**             | Experiment Tracking      | [http://localhost:8088/mlflow/](http://localhost:8088/mlflow/)               | [http://localhost:5000](http://localhost:5000)   | -                          |
| **Agent Orchestrator** | LangGraph Agents API     | [http://localhost:8088/agents/](http://localhost:8088/agents/)               | [http://localhost:8095](http://localhost:8095)   | -                          |
| **RAG Pipeline**       | Haystack RAG API         | [http://localhost:8088/rag/](http://localhost:8088/rag/)                     | [http://localhost:8096](http://localhost:8096)   | -                          |
| **MinIO Console**      | Object Storage UI        | [http://localhost:8088/minio-console/](http://localhost:8088/minio-console/) | [http://localhost:9001](http://localhost:9001)   | `minio` / `minio123`       |
| **MinIO API**          | S3-compatible API        | [http://localhost:8088/minio/](http://localhost:8088/minio/)                 | [http://localhost:9000](http://localhost:9000)   | `minio` / `minio123`       |
| **Neo4j**              | Graph Database UI        | [http://localhost:8088/neo4j/](http://localhost:8088/neo4j/)                 | [http://localhost:7474](http://localhost:7474)   | `neo4j` / `cortexia123`    |
| **Qdrant**             | Vector Database API      | [http://localhost:8088/qdrant/](http://localhost:8088/qdrant/)               | [http://localhost:6333](http://localhost:6333)   | -                          |
| **Grafana**            | Observability Dashboards | [http://localhost:8088/grafana/](http://localhost:8088/grafana/)             | [http://localhost:3000](http://localhost:3000)   | `admin` / `admin`          |
| **Prometheus**         | Metrics Server           | [http://localhost:8088/prometheus/](http://localhost:8088/prometheus/)       | [http://localhost:9090](http://localhost:9090)   | -                          |
| **Ollama**             | Local LLM Inference      | N/A                                                                          | [http://localhost:11434](http://localhost:11434) | -                          |
| **Agent Registry**     | Registry API             | N/A                                                                          | [http://localhost:8090](http://localhost:8090)   | -                          |
| **Vault**              | Secrets Management       | N/A                                                                          | [http://localhost:8200](http://localhost:8200)   | Root Token (Dev)           |
| **OPA**                | Policy Engine            | N/A                                                                          | [http://localhost:8181](http://localhost:8181)   | -                          |
| **PostgreSQL**         | Metadata Database        | N/A                                                                          | `localhost:5434`                                 | `cortexia` / `cortexia123` |

> **Note**: URLs ending in `/` in the Proxy column require the trailing slash to work correctly.
