#!/bin/bash
set -e

# Configuration
REGION="us-east-1"
STACK_NAME="moziostackdemo2"
ECR_REPO_NAME="moziorepoecr"

# Check if AWS_ACCOUNT_ID is set
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "Error: AWS_ACCOUNT_ID environment variable is not set"
    exit 1
fi

# Build Docker image in parallel with ECR repository creation
echo "Building Docker image..."
docker build -t ${ECR_REPO_NAME} . --no-cache &
BUILD_PID=$!

echo "Creating/checking ECR repository..."
aws ecr create-repository --repository-name ${ECR_REPO_NAME} --region ${REGION} || true

# Wait for build to complete
wait $BUILD_PID

# Login and push to ECR
echo "Pushing Docker image..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.${REGION}.amazonaws.com"
docker tag "${ECR_REPO_NAME}:latest" "$AWS_ACCOUNT_ID.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO_NAME}:latest"
docker push "$AWS_ACCOUNT_ID.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO_NAME}:latest"

# Deploy CloudFormation stack with faster options
echo "Deploying CloudFormation stack..."
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
echo "Getting application URL..."
ALB_URL=$(aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text)

echo "Deployment in progress..."
echo "You can access the application at: http://${ALB_URL}"
echo "(Note: It may take a few minutes for the application to become available)" 
