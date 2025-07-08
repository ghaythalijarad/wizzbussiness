#!/bin/bash

# AWS Deployment Script for Order Receiver Application
# This script automates the complete deployment process

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="order-receiver"
AWS_REGION="eu-north-1"
BACKEND_DIR="../backend"
FRONTEND_DIR="../frontend"
INFRASTRUCTURE_DIR="."

echo -e "${BLUE}🚀 Starting AWS deployment for Order Receiver Application${NC}"

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed${NC}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi

# Check AWS credentials
echo -e "${YELLOW}🔑 Verifying AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured${NC}"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✅ AWS Account: ${AWS_ACCOUNT_ID}${NC}"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${RED}❌ terraform.tfvars not found${NC}"
    echo -e "${YELLOW}Please copy terraform.tfvars.example to terraform.tfvars and fill in your values${NC}"
    exit 1
fi

# Initialize Terraform
echo -e "${YELLOW}🏗️  Initializing Terraform...${NC}"
terraform init

# Plan infrastructure
echo -e "${YELLOW}📊 Planning infrastructure changes...${NC}"
terraform plan

# Ask for confirmation
echo -e "${YELLOW}❓ Do you want to proceed with the deployment? (y/N)${NC}"
read -r confirmation
if [[ $confirmation != [yY] && $confirmation != [yY][eE][sS] ]]; then
    echo -e "${YELLOW}⏹️  Deployment cancelled${NC}"
    exit 0
fi

# Apply infrastructure
echo -e "${YELLOW}🏗️  Creating AWS infrastructure...${NC}"
terraform apply -auto-approve

# Get outputs
ECR_REPOSITORY_URL=$(terraform output -raw ecr_repository_url)
ALB_DNS_NAME=$(terraform output -raw load_balancer_dns)
S3_BUCKET_NAME=$(terraform output -raw frontend_bucket_name)
CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_domain_name)

echo -e "${GREEN}✅ Infrastructure created successfully!${NC}"
echo -e "${BLUE}📦 ECR Repository: ${ECR_REPOSITORY_URL}${NC}"
echo -e "${BLUE}🌐 Load Balancer: ${ALB_DNS_NAME}${NC}"
echo -e "${BLUE}📱 Frontend URL: https://${CLOUDFRONT_DOMAIN}${NC}"

# Build and push Docker image
echo -e "${YELLOW}🐳 Building and pushing Docker image...${NC}"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URL

# Build Docker image
cd $BACKEND_DIR
docker build -t $PROJECT_NAME-backend .

# Tag and push image
docker tag $PROJECT_NAME-backend:latest $ECR_REPOSITORY_URL:latest
docker push $ECR_REPOSITORY_URL:latest

echo -e "${GREEN}✅ Docker image pushed successfully!${NC}"

# Update ECS service to use new image
echo -e "${YELLOW}🔄 Updating ECS service...${NC}"
cd ../infrastructure

# Force ECS service update
aws ecs update-service \
    --cluster $PROJECT_NAME-cluster \
    --service $PROJECT_NAME-service \
    --force-new-deployment \
    --region $AWS_REGION

echo -e "${GREEN}✅ ECS service updated!${NC}"

# Build and deploy frontend (if Flutter web build exists)
if [ -d "$FRONTEND_DIR/build/web" ]; then
    echo -e "${YELLOW}📱 Deploying frontend to S3...${NC}"
    
    # Sync files to S3
    aws s3 sync $FRONTEND_DIR/build/web s3://$S3_BUCKET_NAME/ --delete
    
    # Invalidate CloudFront cache
    CLOUDFRONT_DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
    aws cloudfront create-invalidation \
        --distribution-id $CLOUDFRONT_DISTRIBUTION_ID \
        --paths "/*"
    
    echo -e "${GREEN}✅ Frontend deployed successfully!${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend build not found. Run 'flutter build web' in the frontend directory first.${NC}"
fi

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${BLUE}📝 Access your application:${NC}"
echo -e "${BLUE}   Backend API: http://${ALB_DNS_NAME}${NC}"
echo -e "${BLUE}   Frontend: https://${CLOUDFRONT_DOMAIN}${NC}"
echo -e "${BLUE}   API Docs: http://${ALB_DNS_NAME}/docs${NC}"

echo -e "${YELLOW}⏳ Note: It may take a few minutes for the ECS service to update and become healthy.${NC}"
