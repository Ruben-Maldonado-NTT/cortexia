# CortexIA: Operator Guide (OP)

This guide covers the operational lifecycle, observability, and management of the CortexIA platform for DevOps engineers.

## ⚙️ 1. Platform Management

### Infrastructure
*   **Kubernetes (Minikube)**: The platform runs on a local K8s cluster.
*   **Startup (Recommended)**: `minikube start --cpus 8 --memory 12288 --addons=ingress`
*   **Startup (Fallback)**: `minikube start --cpus 4 --memory 7000 --addons=ingress` (If Docker limit is 8GB)
*   **Important**: If you get a memory error, increase the resources in **Docker Desktop Settings -> Resources -> Memory** to at least 14GB.
*   **Tunneling**: `minikube tunnel` (Required for Ingress/LoadBalancer on macOS).

### Deployment Lifecycle
We use a **Layered Deployment Strategy**:
1.  **Platform**: Namespaces, Secrets (`kubectl apply -f kubernetes/platform/`).
2.  **Foundation**: Databases (`postgres`, `minio`). Wait for readiness.
3.  **Control Plane**: core logic (`kong`, `kafka`).
4.  **Applications**: Brain, Experience, Governance layers.

**Script**: `scripts/deploy_k8s.sh` automates this sequence.

---

## 🔭 2. Observability & Monitoring

### Metrics (Prometheus & Grafana)
*   **Grafana**: [http://grafana.localhost](http://grafana.localhost) (User: `admin` / Pass: `admin`)
*   **Prometheus**: [http://prometheus.localhost](http://prometheus.localhost)

### Tracing (Opik)
*   **Tool**: Opik (Comet)
*   **Access**: [http://opik.localhost](http://opik.localhost)
*   **Usage**: Trace agent execution flows, latency, and tool usage steps.

### Policy Enforcement (OPA)
*   **Tool**: Open Policy Agent
*   **Config**: `kubernetes/governance/opa-configmap.yaml`
*   **Logs**: Check `kubectl logs -l app=cortexia-opa` for decision logs.

---

## 🔄 3. CI/CD & Promotion

### Build Pipeline
1.  **Code Change**: Developer pushes to Git.
2.  **Validation**: Run `scripts/validate_k8s.sh` in CI.
3.  **Image Build**:
    *   Images: `cortexia/orchestrator`, `cortexia/rag`.
    *   Registry: Currently local (`minikube image build`). Needs migration to remote registry (ECR/GCR) for prod.

### Promotion Strategy (GitOps)
*   **FluxCD / ArgoCD** (Recommended for future): Sync `kubernetes/` folder to cluster.
*   **Environments**:
    *   *Dev*: Local Minikube.
    *   *Staging*: Namespace `cortexia-staging`.
    *   *Prod*: Namespace `cortexia`.

## 🔑 Platform Credentials

| Service            | Component    | Default Credentials                  |
| :----------------- | :----------- | :----------------------------------- |
| **Infrastructure** | Postgres     | `cortexia` / `cortexia123`           |
| **Infrastructure** | MinIO        | `minio` / `minio123`                 |
| **Gateways**       | LiteLLM      | `sk-cortexia-admin-key`              |
| **Experience**     | Flowise      | User-defined (in Postgres `flowise`) |
| **Experience**     | OpenMetadata | `admin` / `admin`                    |

## 🚨 4. Incident Response

| Symptom              | Check                      | Action                                              |
| :------------------- | :------------------------- | :-------------------------------------------------- |
| **Ingress 404**      | `minikube tunnel` running? | Restart tunnel.                                     |
| **Pod CrashLoop**    | `kubectl logs <pod>`       | Check missing Secrets or DB connection.             |
| **ImagePullBackOff** | Internet / Registry        | Verify Docker Hub rate limits or local image cache. |
