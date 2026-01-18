#!/bin/bash
# CortexIA Kubernetes Deployment Script

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# 1. Platform Setup
log_info "Deploying Platform Resources (Namespace, Secrets, ConfigMaps)..."
kubectl apply -f kubernetes/platform/namespace.yaml
sleep 2
kubectl apply -f kubernetes/platform/
log_success "Platform resources applied."

# 2. Foundation Layer
log_info "Deploying Foundation Layer (Databases, Storage)..."
kubectl apply -f kubernetes/foundation/
log_info "Waiting for Foundation services to be ready..."
kubectl wait --for=condition=ready pod -l app=cortexia-postgres -n cortexia --timeout=120s || log_warning "Postgres not ready yet"
kubectl wait --for=condition=ready pod -l app=cortexia-minio -n cortexia --timeout=120s || log_warning "MinIO not ready yet"
log_success "Foundation layer applied."

# 3. Control Plane
log_info "Deploying Control Plane (Kong, Kafka)..."
kubectl apply -f kubernetes/control-plane/
log_success "Control Plane applied."

# 4. Models Layer
log_info "Deploying Models Layer (LiteLLM, Ollama)..."
kubectl apply -f kubernetes/models/
log_success "Models layer applied."

# 5. Brain Layer
log_info "Deploying Brain Layer (Orchestrator, RAG, Registry)..."
kubectl apply -f kubernetes/brain/
log_success "Brain layer applied."

# 6. Experience Layer
log_info "Deploying Experience Layer (Flowise, Backstage)..."
kubectl apply -f kubernetes/experience/
log_success "Experience layer applied."

# 7. Governance Layer
log_info "Deploying Governance Layer (Opik, OPA)..."
kubectl apply -f kubernetes/governance/
log_success "Governance layer applied."

# 8. Monitoring Layer
log_info "Deploying Monitoring Layer (Prometheus, Grafana)..."
kubectl apply -f kubernetes/monitoring/
log_success "Monitoring layer applied."

# 9. Ingress
log_info "Deploying Ingress..."
kubectl apply -f kubernetes/ingress/
log_success "Ingress applied."

echo ""
log_success "Deployment commands executed successfully!"
log_info "Check status with: kubectl get pods -n cortexia"
log_info "Once Ingress controller is active, access via http://localhost (or your cluster IP)"
