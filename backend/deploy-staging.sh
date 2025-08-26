#!/bin/bash

# Deploy Order Receiver Backend to Staging
# This script deploys the AWS SAM application to the staging environment

set -e

echo "🚀 Starting deployment to staging environment..."

# Set variables
REGION="us-east-1"
STACK_NAME="order-receiver-regional-dev"
S3_BUCKET="order-receiver-deployment-artifacts-${REGION}"
STAGE="dev"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI first."
    exit 1
fi

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    echo "❌ SAM CLI not found. Please install SAM CLI first."
    exit 1
fi

# Navigate to backend directory
cd "$(dirname "$0")"

echo "📂 Current directory: $(pwd)"

# Build the SAM application
echo "🔨 Building SAM application..."
sam build

# Deploy the application
echo "🚀 Deploying to AWS..."
sam deploy \
  --stack-name "${STACK_NAME}" \
  --resolve-s3 \
  --region "${REGION}" \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    Stage="${STAGE}" \
    CognitoUserPoolId="us-east-1_PHPkG78b5" \
    CognitoClientId="1tl9g7nk2k2chtj5fg960fgdth" \
  --no-confirm-changeset

# Get the API Gateway endpoint
echo "🔗 Getting API Gateway endpoint..."
API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name "${STACK_NAME}" \
  --region "${REGION}" \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayEndpoint`].OutputValue' \
  --output text)

echo "✅ Deployment completed!"
echo "🌐 API Gateway Endpoint: ${API_ENDPOINT}"
echo ""
echo "📋 Business Profile Endpoints:"
echo "   GET  ${API_ENDPOINT}businesses/{businessId}/profile"
echo "   PUT  ${API_ENDPOINT}businesses/{businessId}/profile"
echo ""
echo "🔐 Authentication required: Bearer token from AWS Cognito"