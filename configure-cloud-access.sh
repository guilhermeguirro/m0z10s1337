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

# Print banner
echo -e "${BLUE}"
echo "====================================================="
echo "    Chaos Engineering Cloud Provider Configuration    "
echo "====================================================="
echo -e "${NC}"

# Function to show help
show_help() {
  echo "Usage: $0 --provider <provider> [options]"
  echo
  echo "Configure cloud provider access for the Chaos Engineering platform"
  echo
  echo "Options:"
  echo "  --provider PROVIDER    Cloud provider (aws, gcp, azure)"
  echo "  --region REGION        Cloud provider region"
  echo "  --profile PROFILE      AWS profile name (for AWS only)"
  echo "  --project PROJECT      GCP project ID (for GCP only)"
  echo "  --subscription SUB     Azure subscription ID (for Azure only)"
  echo "  --help                 Show this help message"
  echo
  echo "Examples:"
  echo "  $0 --provider aws --region us-west-2 --profile prod"
  echo "  $0 --provider gcp --project my-project-id"
  echo "  $0 --provider azure --subscription sub-id"
  exit 0
}

# Parse arguments
PROVIDER=""
REGION=""
PROFILE=""
PROJECT=""
SUBSCRIPTION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)
      PROVIDER="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --project)
      PROJECT="$2"
      shift 2
      ;;
    --subscription)
      SUBSCRIPTION="$2"
      shift 2
      ;;
    --help)
      show_help
      ;;
    *)
      echo -e "${RED}Error: Unknown option $1${NC}"
      show_help
      ;;
  esac
done

# Check if provider is specified
if [ -z "$PROVIDER" ]; then
  echo -e "${RED}Error: Provider is required${NC}"
  show_help
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo -e "${RED}Error: kubectl is not installed. Please install kubectl first.${NC}"
  exit 1
fi

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
  echo -e "${RED}Error: Namespace $NAMESPACE does not exist. Please deploy the platform first.${NC}"
  exit 1
fi

# Configure AWS
configure_aws() {
  echo -e "${YELLOW}Configuring AWS access...${NC}"
  
  # Set default region if not provided
  if [ -z "$REGION" ]; then
    REGION="us-east-1"
    echo -e "${YELLOW}No region specified, using default: $REGION${NC}"
  fi
  
  # Check if AWS CLI is installed
  if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed. Please install it first.${NC}"
    exit 1
  fi
  
  # Create AWS credentials secret
  echo "Creating AWS credentials secret..."
  
  # If profile is specified, use it to get credentials
  if [ -n "$PROFILE" ]; then
    echo "Using AWS profile: $PROFILE"
    AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile "$PROFILE")
    AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile "$PROFILE")
  else
    # Otherwise use default profile
    AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
    AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
  fi
  
  # Check if credentials were retrieved
  if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo -e "${RED}Error: Failed to retrieve AWS credentials${NC}"
    exit 1
  fi
  
  # Create Kubernetes secret
  kubectl create secret generic aws-credentials \
    --namespace "$NAMESPACE" \
    --from-literal=aws_access_key_id="$AWS_ACCESS_KEY_ID" \
    --from-literal=aws_secret_access_key="$AWS_SECRET_ACCESS_KEY" \
    --from-literal=aws_region="$REGION" \
    --dry-run=client -o yaml | kubectl apply -f -
  
  # Update ConfigMap to enable AWS agent
  kubectl get configmap chaos-control-plane-config -n "$NAMESPACE" -o yaml | \
    sed 's/aws:\n        enabled: false/aws:\n        enabled: true/' | \
    kubectl apply -f -
  
  echo -e "${GREEN}AWS access configured successfully!${NC}"
}

# Configure GCP
configure_gcp() {
  echo -e "${YELLOW}Configuring GCP access...${NC}"
  
  # Check if gcloud is installed
  if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed. Please install it first.${NC}"
    exit 1
  fi
  
  # Check if project is specified
  if [ -z "$PROJECT" ]; then
    echo -e "${RED}Error: GCP project ID is required${NC}"
    exit 1
  fi
  
  # Create service account key
  echo "Creating service account for Chaos Engineering..."
  SA_NAME="chaos-engineering-sa"
  SA_EMAIL="$SA_NAME@$PROJECT.iam.gserviceaccount.com"
  
  # Check if service account exists
  if ! gcloud iam service-accounts describe "$SA_EMAIL" --project "$PROJECT" &> /dev/null; then
    echo "Creating service account: $SA_NAME"
    gcloud iam service-accounts create "$SA_NAME" \
      --display-name="Chaos Engineering Service Account" \
      --project="$PROJECT"
  fi
  
  # Grant necessary permissions
  echo "Granting permissions to service account..."
  gcloud projects add-iam-policy-binding "$PROJECT" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/compute.instanceAdmin.v1"
  
  gcloud projects add-iam-policy-binding "$PROJECT" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/container.admin"
  
  # Create and download key
  echo "Creating service account key..."
  KEY_FILE="gcp-key.json"
  gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$SA_EMAIL" \
    --project="$PROJECT"
  
  # Create Kubernetes secret
  kubectl create secret generic gcp-credentials \
    --namespace "$NAMESPACE" \
    --from-file=credentials.json="$KEY_FILE" \
    --dry-run=client -o yaml | kubectl apply -f -
  
  # Clean up key file
  rm "$KEY_FILE"
  
  # Update ConfigMap to enable GCP agent
  kubectl get configmap chaos-control-plane-config -n "$NAMESPACE" -o yaml | \
    sed 's/gcp:\n        enabled: false/gcp:\n        enabled: true/' | \
    kubectl apply -f -
  
  echo -e "${GREEN}GCP access configured successfully!${NC}"
}

# Configure Azure
configure_azure() {
  echo -e "${YELLOW}Configuring Azure access...${NC}"
  
  # Check if Azure CLI is installed
  if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed. Please install it first.${NC}"
    exit 1
  fi
  
  # Check if subscription is specified
  if [ -z "$SUBSCRIPTION" ]; then
    echo -e "${RED}Error: Azure subscription ID is required${NC}"
    exit 1
  fi
  
  # Create service principal
  echo "Creating service principal for Chaos Engineering..."
  SP_NAME="chaos-engineering-sp"
  
  # Create service principal and capture output
  SP_OUTPUT=$(az ad sp create-for-rbac --name "$SP_NAME" --role Contributor --scopes "/subscriptions/$SUBSCRIPTION" --query "{clientId:appId,clientSecret:password,tenantId:tenant}" -o json)
  
  # Extract credentials
  CLIENT_ID=$(echo "$SP_OUTPUT" | jq -r '.clientId')
  CLIENT_SECRET=$(echo "$SP_OUTPUT" | jq -r '.clientSecret')
  TENANT_ID=$(echo "$SP_OUTPUT" | jq -r '.tenantId')
  
  # Create Kubernetes secret
  kubectl create secret generic azure-credentials \
    --namespace "$NAMESPACE" \
    --from-literal=client_id="$CLIENT_ID" \
    --from-literal=client_secret="$CLIENT_SECRET" \
    --from-literal=tenant_id="$TENANT_ID" \
    --from-literal=subscription_id="$SUBSCRIPTION" \
    --dry-run=client -o yaml | kubectl apply -f -
  
  # Update ConfigMap to enable Azure agent
  kubectl get configmap chaos-control-plane-config -n "$NAMESPACE" -o yaml | \
    sed 's/azure:\n        enabled: false/azure:\n        enabled: true/' | \
    kubectl apply -f -
  
  echo -e "${GREEN}Azure access configured successfully!${NC}"
}

# Configure based on provider
case "$PROVIDER" in
  aws)
    configure_aws
    ;;
  gcp)
    configure_gcp
    ;;
  azure)
    configure_azure
    ;;
  *)
    echo -e "${RED}Error: Unsupported provider: $PROVIDER${NC}"
    show_help
    ;;
esac

# Restart control plane to apply changes
echo -e "${YELLOW}Restarting control plane to apply changes...${NC}"
kubectl rollout restart deployment/chaos-control-plane -n "$NAMESPACE"

# Wait for control plane to be ready
echo "Waiting for control plane to be ready..."
kubectl rollout status deployment/chaos-control-plane -n "$NAMESPACE" --timeout=300s

echo -e "${GREEN}"
echo "====================================================="
echo "    Cloud Provider Configuration Complete!           "
echo "====================================================="
echo -e "${NC}"
echo "You can now run experiments against $PROVIDER resources."
echo

exit 0
