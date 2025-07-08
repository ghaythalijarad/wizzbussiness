#!/bin/bash

# SAM deployment script for serverless order receiver backend
set -e

echo "🚀 Starting SAM deployment of Order Receiver Serverless Backend"

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    echo "❌ SAM CLI is not installed. Please install it first:"
    echo "pip install aws-sam-cli"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Get deployment parameters
ENVIRONMENT=${1:-dev}
REGION=${2:-us-east-1}
STACK_NAME="order-receiver-serverless-$ENVIRONMENT"

echo "📋 SAM Deployment Configuration:"
echo "   Environment: $ENVIRONMENT"
echo "   Region: $REGION"
echo "   Stack Name: $STACK_NAME"
echo ""

# Navigate to backend directory
cd "$(dirname "$0")"

# Build the SAM application
echo "🔨 Building SAM application..."
sam build --use-container

# Validate the template
echo "🔍 Validating SAM template..."
sam validate

# Deploy the application
echo "🚀 Deploying to AWS with SAM..."
sam deploy \
    --stack-name $STACK_NAME \
    --region $REGION \
    --parameter-overrides \
        Environment=$ENVIRONMENT \
        CorsOrigins="*" \
    --capabilities CAPABILITY_IAM \
    --no-confirm-changeset \
    --no-fail-on-empty-changeset

# Get stack outputs
echo "📊 Getting stack outputs..."
API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
    --output text 2>/dev/null || echo "Not available")

echo ""
echo "✅ SAM deployment completed successfully!"
echo ""
echo "📊 Deployment Summary:"
echo "   Stack Name: $STACK_NAME"
echo "   API Endpoint: $API_ENDPOINT"
echo "   Environment: $ENVIRONMENT"
echo "   Region: $REGION"
echo ""
echo "🧪 Test your deployment:"
echo "   Health Check: curl $API_ENDPOINT/health"
echo "   Auth Health: curl $API_ENDPOINT/auth/health"
echo ""
echo "📚 Next steps:"
echo "   1. Update your frontend to use the new API endpoint"
echo "   2. Test all endpoints thoroughly"
echo "   3. Monitor CloudWatch logs for any issues"
echo ""
echo "🗂️  Useful commands:"
echo "   View logs: sam logs --stack-name $STACK_NAME"
echo "   Local testing: sam local start-api"
echo "   Delete stack: sam delete --stack-name $STACK_NAME"
