# CortexIA Quick Start Guide (Kubernetes)

This guide helps you get the CortexIA platform up and running in less than 10 minutes using Kubernetes.

## 🛠 Prerequisites

Ensure your environment meets these requirements:
- **Docker Desktop**: Allocated at least **8 CPUs** and **14GB RAM**.
- **Minikube**: Installed (`brew install minikube`).
- **kubectl**: Installed (`brew install kubernetes-cli`).

## 🚀 1. Installation

```bash
# Clone the repository
git clone https://github.com/Ruben-Maldonado-NTT/cortexia.git
cd cortexia

# Launch the automated startup
./start.sh
```

## 🌉 2. Enable Connectivity (macOS Only)

Open a **new terminal tab** and run the Minikube tunnel. This is essential for routing `*.localhost` traffic to your cluster:

```bash
sudo minikube tunnel
```
*Keep this terminal open while using the platform.*

## 🎨 3. Access the Platform

Once the pods are ready (`kubectl get pods -n cortexia`), open your browser:

| Service                   | URL                                                        |
| :------------------------ | :--------------------------------------------------------- |
| **Designer (Flowise)**    | [http://flowise.localhost](http://flowise.localhost)       |
| **Model Admin (LiteLLM)** | [http://litellm.localhost/ui](http://litellm.localhost/ui) |
| **Tracing (Opik)**        | [http://opik.localhost](http://opik.localhost)             |
| **Dashboards (Grafana)**  | [http://grafana.localhost](http://grafana.localhost)       |

## 🧪 4. Quick Test: Model Gateway

Verify that the local AI models are accessible via the LiteLLM proxy:

```bash
curl http://litellm.localhost/v1/models \
  -H "Authorization: Bearer sk-cortexia-admin-key"
```

## 🐳 Legacy Docker Flow (Optional)
If you prefer using Docker Compose for simple testing without Ingress:
```bash
cd docker && docker compose up -d
```
*Note: Advanced features like Opik and host-based routing are only available in the Kubernetes version.*

---
**Last Updated**: 2026-01-18
