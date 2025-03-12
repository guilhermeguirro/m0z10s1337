#!/bin/bash
set -e

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
NAMESPACE="chaos-engineering"
CONTROL_PLANE_IMAGE="chaos-engineering/control-plane:v1.0.0"
KUBERNETES_AGENT_IMAGE="chaos-engineering/kubernetes-agent:v1.0.0"

# Print banner
echo -e "${GREEN}"
echo "====================================================="
echo "       Chaos Engineering Platform Deployment         "
echo "====================================================="
echo -e "${NC}"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Check if user is authenticated with Kubernetes
echo "Checking Kubernetes connection..."
if ! kubectl get nodes &> /dev/null; then
    echo -e "${RED}Error: Failed to connect to Kubernetes cluster. Please check your kubeconfig.${NC}"
    exit 1
fi

# Create namespace if it doesn't exist
echo "Creating namespace if it doesn't exist..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Function to deploy manifests
deploy_manifests() {
    local dir=$1
    local component=$2
    
    echo -e "${YELLOW}Deploying $component...${NC}"
    for file in $dir/*.yaml; do
        if [ -f "$file" ]; then
            echo "Applying $file..."
            kubectl apply -f "$file"
        fi
    done
}

# Deploy CRDs
echo "Deploying Custom Resource Definitions..."
kubectl apply -f manifests/crds/ --server-side || {
    echo -e "${YELLOW}Warning: CRDs directory not found or error applying CRDs. Continuing...${NC}"
}

# Deploy control plane
deploy_manifests "manifests/control-plane" "control plane"

# Wait for control plane to be ready
echo "Waiting for control plane to be ready..."
kubectl rollout status deployment/chaos-control-plane -n $NAMESPACE --timeout=300s || {
    echo -e "${RED}Error: Control plane deployment timed out.${NC}"
    exit 1
}

# Deploy agents
deploy_manifests "manifests/agents" "agents"

# Wait for agents to be ready
echo "Waiting for Kubernetes agent to be ready..."
kubectl rollout status daemonset/chaos-kubernetes-agent -n $NAMESPACE --timeout=300s || {
    echo -e "${RED}Error: Kubernetes agent deployment timed out.${NC}"
    exit 1
}

# Check if everything is running
echo "Checking deployment status..."
kubectl get all -n $NAMESPACE

# Print success message
echo -e "${GREEN}"
echo "====================================================="
echo "       Chaos Engineering Platform Deployed!          "
echo "====================================================="
echo ""
echo "Control Plane URL: http://chaos-control-plane.$NAMESPACE.svc.cluster.local"
echo ""
echo "To run your first experiment:"
echo "kubectl apply -f examples/pod-failure-experiment.yaml"
echo -e "${NC}"

exit 0 