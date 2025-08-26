#!/bin/bash

# Quick Document Upload Fix Deployment
echo "🚀 Quick Document Upload Fix Deployment"
echo "======================================="

# Check credentials
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ Please run 'aws configure' first to set up your credentials"
    exit 1
fi

echo "✅ AWS credentials valid"

# Deploy
cd /Users/ghaythallaheebi/order-receiver-app-2/backend
echo "🔨 Building..."
sam build

echo "🚀 Deploying..."
sam deploy --no-confirm-changeset

echo ""
echo "✅ DEPLOYMENT COMPLETE!"
echo ""
echo "🎯 Document upload fix is now live!"
echo "Test by registering with multiple documents - all should be saved to DynamoDB."
