# CortexIA Platform

**CortexIA** is a modular, local-first Agentic AI Platform designed to orchestrate, govern, and observe autonomous agents. It integrates best-in-class open-source tools into a unified ecosystem for building enterprise-grade AI applications.

## 🏗 Architecture

The platform is organized into logical layers:

*   **Foundation**: Core infrastructure (Storage, Networking).
*   **Security & Governance**: Identity, Secrets, Policies (OPA), and Tracing (Opik).
*   **Brain & Runtime**: Model serving (LiteLLM/Ollama), Agent Orchestration, and RAG.
*   **Control Plane**: Kong API Gateway and Kafka Event Backbone.
*   **Experience**: Developer Portal (Backstage) and Visual Designer (Flowise).
*   **Observability**: Metrics (Prometheus) and Dashboards (Grafana).

## 🚀 Getting Started (Kubernetes)

### Prerequisites
*   **Docker Desktop** (>= 20.10) with **14GB RAM** allocated.
*   **Minikube** (>= 1.34)
*   **kubectl**

### Installation & Running

The platform is optimized for **Kubernetes (Minikube)**. Use the unified startup script for the best experience:

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/Ruben-Maldonado-NTT/cortexia.git
    cd cortexia
    ```

2.  **Start the Platform**:
    ```bash
    ./start.sh
    ```
    This script will:
    - Verify Minikube status and resources.
    - Start Minikube with the required configuration if needed.
    - Deploy all platform layers in order.
    - Verify Ingress connectivity.

3.  **Local Access (macOS)**:
    On macOS, you **MUST** run the tunnel in a separate terminal:
    ```bash
    sudo minikube tunnel
    ```

## 📚 Service Catalog

The platform uses **Host-based Ingress**. Access the following services via their `.localhost` domains:

| Service           | Role                  | Kubernetes URL                                             | Default Credentials     |
| :---------------- | :-------------------- | :--------------------------------------------------------- | :---------------------- |
| **Flowise**       | Visual Agent Designer | [http://flowise.localhost](http://flowise.localhost)       | Setup on first access   |
| **Backstage**     | Developer Portal      | [http://backstage.localhost](http://backstage.localhost)   | -                       |
| **LiteLLM UI**    | Model Gateway Admin   | [http://litellm.localhost/ui](http://litellm.localhost/ui) | `sk-cortexia-admin-key` |
| **Opik**          | Agent Tracing & Eval  | [http://opik.localhost](http://opik.localhost)             | -                       |
| **Grafana**       | Monitoring Dashboards | [http://grafana.localhost](http://grafana.localhost)       | `admin` / `admin`       |
| **Prometheus**    | Metrics Engine        | [http://prometheus.localhost](http://prometheus.localhost) | -                       |
| **MinIO Console** | Object Storage UI     | [http://minio.localhost](http://minio.localhost)           | `minio` / `minio123`    |
| **Neo4j**         | Graph Database UI     | [http://neo4j.localhost](http://neo4j.localhost)           | `neo4j` / `cortexia123` |

---

## 🛠 Advanced Management

### View Logs
```bash
# View logs for a specific component (e.g., flowise)
kubectl logs -l app=cortexia-flowise -n cortexia -f
```

### Manual Deployment
```bash
./scripts/deploy_k8s.sh
```

### Troubleshooting
- **DNS Issues**: Ensure `minikube tunnel` is active.
- **Memory**: Verify Docker Desktop has 14GB+ RAM.
- **Port 80/443**: Ensure no other process (like Apache or Nginx) is using these ports on your Mac.

---
**Version**: 1.0 (Kubernetes Native)
