#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="chaos-engineering"
VAULT_NAMESPACE="vault"
HELM_CHART_VERSION="0.23.0"

# Print banner
echo -e "${BLUE}"
echo "====================================================="
echo "    Chaos Engineering Vault Secrets Setup            "
echo "====================================================="
echo -e "${NC}"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo -e "${RED}Error: helm is not installed. Please install helm first.${NC}"
    exit 1
fi

# Check if user is authenticated with Kubernetes
echo "Checking Kubernetes connection..."
if ! kubectl get nodes &> /dev/null; then
    echo -e "${RED}Error: Failed to connect to Kubernetes cluster. Please check your kubeconfig.${NC}"
    exit 1
fi

# Create Vault namespace if it doesn't exist
echo "Creating Vault namespace if it doesn't exist..."
kubectl create namespace $VAULT_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add HashiCorp Helm repository
echo "Adding HashiCorp Helm repository..."
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Install Vault using Helm
echo -e "${YELLOW}Installing Vault...${NC}"
helm upgrade --install vault hashicorp/vault \
  --namespace $VAULT_NAMESPACE \
  --version $HELM_CHART_VERSION \
  --values manifests/vault/values.yaml

# Wait for Vault pods to be ready
echo "Waiting for Vault pods to be ready..."
kubectl -n $VAULT_NAMESPACE wait --for=condition=Ready pod/vault-0 --timeout=300s || {
    echo -e "${RED}Error: Vault pod vault-0 not ready.${NC}"
    exit 1
}

# Initialize Vault
echo -e "${YELLOW}Initializing Vault...${NC}"
INIT_RESPONSE=$(kubectl -n $VAULT_NAMESPACE exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json)
UNSEAL_KEY=$(echo $INIT_RESPONSE | jq -r ".unseal_keys_b64[0]")
ROOT_TOKEN=$(echo $INIT_RESPONSE | jq -r ".root_token")

# Save keys to a file (in a real environment, store these securely!)
echo "Saving Vault keys to vault-keys.json..."
echo $INIT_RESPONSE > vault-keys.json
chmod 600 vault-keys.json

# Unseal Vault
echo "Unsealing Vault..."
kubectl -n $VAULT_NAMESPACE exec vault-0 -- vault operator unseal $UNSEAL_KEY

# Login to Vault
echo "Logging in to Vault..."
kubectl -n $VAULT_NAMESPACE exec vault-0 -- vault login $ROOT_TOKEN

# Enable Kubernetes authentication
echo "Enabling Kubernetes authentication..."
kubectl -n $VAULT_NAMESPACE exec vault-0 -- vault auth enable kubernetes

# Configure Kubernetes authentication
echo "Configuring Kubernetes authentication..."
kubectl -n $VAULT_NAMESPACE exec vault-0 -- sh -c 'vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    issuer="https://kubernetes.default.svc.cluster.local"'

# Enable secrets engines
echo "Enabling secrets engines..."
kubectl -n $VAULT_NAMESPACE exec vault-0 -- vault secrets enable -path=chaos-engineering kv-v2

# Create policies for Chaos Engineering
echo "Creating policies for Chaos Engineering..."
kubectl -n $VAULT_NAMESPACE exec vault-0 -- sh -c 'cat > /tmp/chaos-engineering-policy.hcl << EOF
path "chaos-engineering/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF'

kubectl -n $VAULT_NAMESPACE exec vault-0 -- vault policy write chaos-engineering /tmp/chaos-engineering-policy.hcl

# Create Kubernetes role for Chaos Engineering
echo "Creating Kubernetes role for Chaos Engineering..."
kubectl -n $VAULT_NAMESPACE exec vault-0 -- sh -c "vault write auth/kubernetes/role/chaos-engineering \
    bound_service_account_names=chaos-control-plane,chaos-kubernetes-agent \
    bound_service_account_namespaces=$NAMESPACE \
    policies=chaos-engineering \
    ttl=1h"

# Store cloud provider credentials in Vault
echo -e "${YELLOW}Storing cloud provider credentials in Vault...${NC}"

# AWS credentials
if kubectl get secret -n $NAMESPACE aws-credentials &> /dev/null; then
    echo "Migrating AWS credentials to Vault..."
    AWS_ACCESS_KEY_ID=$(kubectl get secret -n $NAMESPACE aws-credentials -o jsonpath='{.data.aws_access_key_id}' | base64 --decode)
    AWS_SECRET_ACCESS_KEY=$(kubectl get secret -n $NAMESPACE aws-credentials -o jsonpath='{.data.aws_secret_access_key}' | base64 --decode)
    AWS_REGION=$(kubectl get secret -n $NAMESPACE aws-credentials -o jsonpath='{.data.aws_region}' | base64 --decode)
    
    kubectl -n $VAULT_NAMESPACE exec vault-0 -- vault kv put chaos-engineering/aws \
        access_key_id="$AWS_ACCESS_KEY_ID" \
        secret_access_key="$AWS_SECRET_ACCESS_KEY" \
        region="$AWS_REGION"
        
    echo "AWS credentials stored in Vault."
fi

# GCP credentials
if kubectl get secret -n $NAMESPACE gcp-credentials &> /dev/null; then
    echo "Migrating GCP credentials to Vault..."
    GCP_CREDENTIALS=$(kubectl get secret -n $NAMESPACE gcp-credentials -o jsonpath='{.data.credentials\.json}' | base64 --decode)
    
    kubectl -n $VAULT_NAMESPACE exec vault-0 -- sh -c "echo '$GCP_CREDENTIALS' > /tmp/gcp-credentials.json"
    kubectl -n $VAULT_NAMESPACE exec vault-0 -- vault kv put chaos-engineering/gcp credentials="@/tmp/gcp-credentials.json"
    kubectl -n $VAULT_NAMESPACE exec vault-0 -- rm /tmp/gcp-credentials.json
    
    echo "GCP credentials stored in Vault."
fi

# Azure credentials
if kubectl get secret -n $NAMESPACE azure-credentials &> /dev/null; then
    echo "Migrating Azure credentials to Vault..."
    AZURE_CLIENT_ID=$(kubectl get secret -n $NAMESPACE azure-credentials -o jsonpath='{.data.client_id}' | base64 --decode)
    AZURE_CLIENT_SECRET=$(kubectl get secret -n $NAMESPACE azure-credentials -o jsonpath='{.data.client_secret}' | base64 --decode)
    AZURE_TENANT_ID=$(kubectl get secret -n $NAMESPACE azure-credentials -o jsonpath='{.data.tenant_id}' | base64 --decode)
    AZURE_SUBSCRIPTION_ID=$(kubectl get secret -n $NAMESPACE azure-credentials -o jsonpath='{.data.subscription_id}' | base64 --decode)
    
    kubectl -n $VAULT_NAMESPACE exec vault-0 -- vault kv put chaos-engineering/azure \
        client_id="$AZURE_CLIENT_ID" \
        client_secret="$AZURE_CLIENT_SECRET" \
        tenant_id="$AZURE_TENANT_ID" \
        subscription_id="$AZURE_SUBSCRIPTION_ID"
        
    echo "Azure credentials stored in Vault."
fi

# Create a ConfigMap with Vault integration information
echo "Creating ConfigMap with Vault integration information..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: vault-integration
  namespace: $NAMESPACE
data:
  VAULT_ADDR: "http://vault.${VAULT_NAMESPACE}.svc.cluster.local:8200"
  VAULT_ROLE: "chaos-engineering"
  VAULT_MOUNT_PATH: "chaos-engineering"
EOF

# Print success message
echo -e "${GREEN}"
echo "====================================================="
echo "    Vault Secrets Manager Setup Complete!            "
echo "====================================================="
echo -e "${NC}"
echo "Vault is now configured for your Chaos Engineering platform."
echo ""
echo "Vault UI: http://vault.${VAULT_NAMESPACE}.svc.cluster.local:8200/ui"
echo ""
echo "IMPORTANT: The root token and unseal key have been saved to vault-keys.json."
echo "           In a production environment, store these securely!"
echo ""
echo "To access Vault from outside the cluster, set up port forwarding:"
echo "kubectl -n ${VAULT_NAMESPACE} port-forward svc/vault 8200:8200"
echo ""

exit 0 