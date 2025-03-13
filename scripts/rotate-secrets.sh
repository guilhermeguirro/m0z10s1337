#!/bin/bash

# Script to simulate HashiCorp Vault and KMS secret rotation during chaos experiments
# Usage: ./rotate-secrets.sh <namespace>

set -e

NAMESPACE=${1:-default}
SECRETS_LABEL="secrets=true"

echo "=== Starting Secret Rotation Chaos Experiment ==="
echo "Target Namespace: $NAMESPACE"
echo "Targeting pods with label: $SECRETS_LABEL"

# Get all pods with the secrets label
PODS=$(kubectl get pods -n $NAMESPACE -l $SECRETS_LABEL -o jsonpath='{.items[*].metadata.name}')

if [ -z "$PODS" ]; then
    echo "No pods found with label $SECRETS_LABEL in namespace $NAMESPACE"
    exit 1
fi

echo "Found pods: $PODS"

# Function to simulate HashiCorp Vault secret rotation
simulate_vault_rotation() {
    local pod=$1
    echo "Simulating HashiCorp Vault secret rotation for pod $pod"
    
    # Create a temporary secret with new values
    NEW_SECRET_NAME="vault-secret-$(date +%s)"
    kubectl create secret generic $NEW_SECRET_NAME -n $NAMESPACE \
        --from-literal=api-key="$(openssl rand -base64 32)" \
        --from-literal=password="$(openssl rand -base64 16)"
    
    # Update pod annotation to trigger a restart and use the new secret
    kubectl annotate pod $pod -n $NAMESPACE vault.hashicorp.com/secret-rotation="$NEW_SECRET_NAME" --overwrite
    
    echo "Vault secret rotated for pod $pod"
}

# Function to simulate AWS KMS key rotation
simulate_kms_rotation() {
    local pod=$1
    echo "Simulating AWS KMS key rotation for pod $pod"
    
    # Create a new KMS key ID (simulated)
    NEW_KMS_KEY_ID="kms-key-$(date +%s)"
    
    # Update pod annotation with new KMS key ID
    kubectl annotate pod $pod -n $NAMESPACE aws-kms/key-id="$NEW_KMS_KEY_ID" --overwrite
    
    # Restart the pod to pick up the new key
    kubectl delete pod $pod -n $NAMESPACE
    
    echo "KMS key rotated for pod $pod"
}

# Rotate secrets for each pod
for pod in $PODS; do
    echo "Processing pod: $pod"
    
    # Randomly choose between Vault and KMS rotation
    if [ $((RANDOM % 2)) -eq 0 ]; then
        simulate_vault_rotation $pod
    else
        simulate_kms_rotation $pod
    fi
    
    # Wait a bit between pods to avoid all pods being down simultaneously
    sleep 5
done

echo "=== Secret Rotation Complete ==="
echo "Monitoring pod status for the next 60 seconds..."

# Monitor pod status for a minute
kubectl get pods -n $NAMESPACE -l $SECRETS_LABEL -w &
WATCH_PID=$!
sleep 60
kill $WATCH_PID

echo "=== Secret Rotation Chaos Experiment Completed ===" 