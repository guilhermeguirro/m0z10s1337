#!/bin/bash
set -e

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Help function
show_help() {
    echo -e "${BLUE}${BOLD}🚀 Mozio ECS Deployment Script${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Usage: ./deploy.sh [OPTIONS] [REGION] [STACK_NAME] [ECR_REPO_NAME]"
    echo
    echo -e "${BOLD}Options:${NC}"
    echo -e "  -h    Show this help message"
    echo
    echo -e "${BOLD}Arguments:${NC}"
    echo -e "  REGION         AWS Region (default: us-east-2)"
    echo -e "  STACK_NAME     CloudFormation stack name (default: moziostackdemo22)"
    echo -e "  ECR_REPO_NAME  ECR repository name (default: moziorepoecrr)"
    echo
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  ./deploy.sh                                     # Deploy with defaults"
    echo -e "  ./deploy.sh us-west-2                          # Deploy to us-west-2"
    echo -e "  ./deploy.sh us-west-2 mystack myrepo          # Deploy with custom names"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
}

# Parse options
while getopts "h" opt; do
    case $opt in
        h)
            show_help
            ;;
        \?)
            echo -e "${RED}Invalid option: -$OPTARG${NC}" >&2
            exit 1
            ;;
    esac
done

# Shift past the options
shift $((OPTIND-1))

# Spinner animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Default Configuration
REGION=${1:-"us-east-2"}
STACK_NAME=${2:-"moziostackdemo22"}
ECR_REPO_NAME=${3:-"moziorepoecrr"}

# Print configuration
echo -e "\n${BLUE}${BOLD}🚀 Starting Mozio ECS Deployment${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Region:${NC} $REGION"
echo -e "${BOLD}Stack Name:${NC} $STACK_NAME"
echo -e "${BOLD}ECR Repository:${NC} $ECR_REPO_NAME"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Check if AWS_ACCOUNT_ID is set
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}❌ Error: AWS_ACCOUNT_ID environment variable is not set${NC}"
    exit 1
fi

# Build Docker image in parallel with ECR repository creation
echo -e "${YELLOW}📦 Building Docker image...${NC}"
docker build -t ${ECR_REPO_NAME} . --no-cache &
BUILD_PID=$!

echo -e "${YELLOW}🏗️  Creating/checking ECR repository...${NC}"
aws ecr create-repository --repository-name ${ECR_REPO_NAME} --region ${REGION} 2>/dev/null || true

# Wait for build to complete
echo -ne "${YELLOW}⏳ Waiting for Docker build to complete...${NC}"
spinner $BUILD_PID
echo -e "${GREEN}✅ Done!${NC}"

# Login and push to ECR
echo -e "\n${YELLOW}🔐 Logging into ECR...${NC}"
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.${REGION}.amazonaws.com"

echo -e "${YELLOW}📤 Pushing Docker image...${NC}"
docker tag "${ECR_REPO_NAME}:latest" "$AWS_ACCOUNT_ID.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO_NAME}:latest"
docker push "$AWS_ACCOUNT_ID.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO_NAME}:latest"

# Deploy CloudFormation stack with faster options
echo -e "\n${YELLOW}🚀 Deploying CloudFormation stack...${NC}"
aws cloudformation deploy \
  --template-file infrastructure.yml \
  --stack-name ${STACK_NAME} \
  --parameter-overrides \
    "EnvironmentName=dev" \
    "ContainerImage=$AWS_ACCOUNT_ID.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO_NAME}:latest" \
    "ContainerPort=3000" \
  --capabilities CAPABILITY_IAM \
  --no-fail-on-empty-changeset \
  --disable-rollback

# Get the ALB URL as soon as it's available
echo -e "\n${YELLOW}🔍 Getting application URL...${NC}"
ALB_URL=$(aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text)

echo -e "\n${GREEN}${BOLD}✨ Deployment Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Deployment in progress${NC}"
echo -e "${BOLD}🌍 Application URL:${NC} http://${ALB_URL}"
echo -e "${YELLOW}⏳ Note: It may take a few minutes for the application to become available${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n" 
