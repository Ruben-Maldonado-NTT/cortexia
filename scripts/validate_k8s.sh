#!/bin/bash

# Configuration
NAMESPACE="cortexia"
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
log_fail() { echo -e "${RED}[FAIL] $1${NC}"; }
log_info() { echo -e "[INFO] $1"; }

check_pod_status() {
    local pod_label=$1
    local status=$(kubectl get pods -n $NAMESPACE -l app=$pod_label -o jsonpath="{.items[0].status.phase}")
    if [ "$status" == "Running" ]; then
        log_success "Pod $pod_label is Running"
    else
        log_fail "Pod $pod_label is $status"
    fi
}

log_info "Starting CortexIA Validation..."

# 1. Foundation
log_info "--- Phase 1: Foundation ---"
check_pod_status "cortexia-postgres"
check_pod_status "cortexia-minio"
check_pod_status "cortexia-qdrant"
check_pod_status "cortexia-neo4j"

# 2. Control Plane
log_info "--- Phase 2: Control Plane ---"
check_pod_status "cortexia-kong"
check_pod_status "cortexia-kafka"

# 3. Models
log_info "--- Phase 3: Models ---"
check_pod_status "cortexia-ollama"
check_pod_status "cortexia-litellm"

# 4. Brain
log_info "--- Phase 4: Brain ---"
check_pod_status "cortexia-orchestrator"
check_pod_status "cortexia-rag"
check_pod_status "cortexia-registry"

# 5. Experience
log_info "--- Phase 5: Experience ---"
check_pod_status "cortexia-flowise"
check_pod_status "cortexia-backstage"

# 6. Governance
log_info "--- Phase 6: Governance ---"
check_pod_status "cortexia-opik-backend"
check_pod_status "cortexia-opa"

log_info "Validation Complete."
