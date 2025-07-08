#!/bin/bash

# Deploy script for serverless order receiver backend
set -e

echo "🚀 Starting deployment of Order Receiver Serverless Backend"

# Check if serverless is installed
if ! command -v serverless &> /dev/null; then
    echo "❌ Serverless Framework is not installed. Please install it first:"
    echo "npm install -g serverless"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Get deployment parameters
STAGE=${1:-dev}
REGION=${2:-us-east-1}

echo "📋 Deployment Configuration:"
echo "   Stage: $STAGE"
echo "   Region: $REGION"
echo ""

# Navigate to backend directory
cd "$(dirname "$0")"

# Install Python dependencies for local development
echo "📦 Installing Python dependencies for development..."
pip install -r requirements.txt

# Install serverless plugins
echo "📦 Installing Serverless plugins..."
npm install

# Validate serverless configuration
echo "🔍 Validating Serverless configuration..."
serverless print --stage $STAGE --region $REGION > /dev/null

# Deploy the application
echo "🚀 Deploying to AWS..."
serverless deploy --stage $STAGE --region $REGION --verbose

# Get the deployed API endpoint
API_ENDPOINT=$(serverless info --stage $STAGE --region $REGION | grep "ServiceEndpoint" | awk '{print $2}')

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📊 Deployment Summary:"
echo "   API Endpoint: $API_ENDPOINT"
echo "   Stage: $STAGE"
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
echo "   View logs: serverless logs -f health --stage $STAGE"
echo "   Remove stack: serverless remove --stage $STAGE"
