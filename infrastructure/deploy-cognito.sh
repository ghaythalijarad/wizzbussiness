#!/bin/bash

# Deploy AWS Cognito resources for Hadhir Business App
set -e

ENVIRONMENT=${1:-production}

echo "🚀 Deploying AWS Cognito resources for environment: $ENVIRONMENT"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

cd infrastructure

# Initialize Terraform
echo "📋 Initializing Terraform..."
terraform init

# Plan the deployment
echo "📊 Planning Cognito deployment..."
terraform plan -var="environment=$ENVIRONMENT" -target=aws_cognito_user_pool.hadhir_business_user_pool -target=aws_cognito_user_pool_client.hadhir_business_client -target=aws_cognito_identity_pool.hadhir_business_identity_pool

# Ask for confirmation
echo ""
read -p "🤔 Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled."
    exit 1
fi

# Apply the deployment
echo "🔨 Deploying Cognito resources..."
terraform apply -var="environment=$ENVIRONMENT" -target=aws_cognito_user_pool.hadhir_business_user_pool -target=aws_cognito_user_pool_client.hadhir_business_client -target=aws_cognito_identity_pool.hadhir_business_identity_pool -auto-approve

# Get the outputs
echo ""
echo "✅ Deployment completed! Here are your Cognito configuration values:"
echo ""
echo "📋 Configuration for .env.$ENVIRONMENT:"
echo "AUTH_MODE=cognito"
echo "COGNITO_USER_POOL_ID=$(terraform output -raw cognito_user_pool_id)"
echo "COGNITO_USER_POOL_CLIENT_ID=$(terraform output -raw cognito_user_pool_client_id)"
echo "COGNITO_REGION=$(terraform output -raw cognito_region)"
echo "COGNITO_IDENTITY_POOL_ID=$(terraform output -raw cognito_identity_pool_id)"
echo ""
echo "💡 Copy these values to your frontend/.env.$ENVIRONMENT file"
echo ""
echo "🧪 To test the setup, run:"
echo "cd ../frontend"
echo "flutter run --dart-define=ENV=$ENVIRONMENT"
