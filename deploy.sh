#!/bin/bash
set -e

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

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

# Configuration
REGION="us-east-1"
STACK_NAME="moziostackdemo2"
ECR_REPO_NAME="moziorepoecr"

# Print header
echo -e "\n${BLUE}${BOLD}🚀 Starting Mozio ECS Deployment${NC}"
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
