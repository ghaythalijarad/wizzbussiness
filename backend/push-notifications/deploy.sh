#!/bin/bash

# Deploy Script for Order Receiver Push Notifications Backend
# This script deploys the updated push notification infrastructure

set -e  # Exit on any error

echo "🚀 Deploying Order Receiver Push Notifications Backend..."

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check if serverless is installed
if ! command -v serverless &> /dev/null; then
    echo "❌ Serverless Framework not found. Installing..."
    npm install -g serverless
fi

# Check if FCM_SERVER_KEY is set
if [ -z "$FCM_SERVER_KEY" ]; then
    echo "❌ FCM_SERVER_KEY environment variable is not set"
    echo "Please set it with: export FCM_SERVER_KEY='your-fcm-server-key'"
    echo "You can get this from Firebase Console > Project Settings > Cloud Messaging"
    exit 1
fi

echo "✅ FCM_SERVER_KEY is set"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured"
    echo "Please run: aws configure"
    exit 1
fi

echo "✅ AWS credentials configured"

# Navigate to backend directory
cd "$(dirname "$0")"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Deploy the stack
echo "🚀 Deploying serverless stack..."
serverless deploy --stage dev --verbose

# Get deployment outputs
echo "📊 Getting deployment information..."
STACK_NAME="push-notifications-dev"
API_ENDPOINT=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`ServiceEndpoint`].OutputValue' --output text)
DEVICE_TOKENS_TABLE=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`DeviceTokensTableName`].OutputValue' --output text)

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "- API Endpoint: $API_ENDPOINT"
echo "- Device Tokens Table: $DEVICE_TOKENS_TABLE"
echo "- Region: us-east-1"
echo ""
echo "🔧 Next Steps:"
echo "1. Update your Flutter app's API configuration with the new endpoint"
echo "2. Test device token registration: POST $API_ENDPOINT/notifications/register-token"
echo "3. Test push notifications: POST $API_ENDPOINT/notifications/send"
echo ""
echo "🧪 Test Commands:"
echo "# Register a device token"
echo "curl -X POST $API_ENDPOINT/notifications/register-token \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \\"
echo "  -d '{\"deviceToken\": \"test-token-123\"}'"
echo ""
echo "# Send a push notification"
echo "curl -X POST $API_ENDPOINT/notifications/send \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \\"
echo "  -d '{\"merchantId\": \"test-merchant\", \"title\": \"Test\", \"message\": \"Hello World\"}'"
echo ""
echo "📚 For more information, see FIREBASE_SETUP.md"
