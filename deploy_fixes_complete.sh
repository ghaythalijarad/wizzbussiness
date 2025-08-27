#!/bin/bash

echo "🚀 Complete Fix Deployment Guide"
echo "================================"
echo ""
echo "This script will help you deploy fixes for:"
echo "  ✅ Business photo upload during registration"
echo "  ✅ WebSocket logout cleanup"
echo "  ✅ Auth handler module path issue"
echo ""

# Step 1: Check AWS credentials
echo "🔐 Step 1: Checking AWS credentials..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    echo "✅ AWS credentials are valid"
    echo "Account: $(aws sts get-caller-identity --query 'Account' --output text)"
    echo "User: $(aws sts get-caller-identity --query 'Arn' --output text)"
else
    echo "❌ AWS credentials are invalid or expired"
    echo ""
    echo "Please configure AWS credentials using one of these methods:"
    echo ""
    echo "Method 1 - AWS Configure:"
    echo "  aws configure"
    echo ""
    echo "Method 2 - Environment Variables:"
    echo "  export AWS_ACCESS_KEY_ID=your_access_key_id"
    echo "  export AWS_SECRET_ACCESS_KEY=your_secret_access_key"
    echo "  export AWS_DEFAULT_REGION=us-east-1"
    echo ""
    echo "Method 3 - AWS SSO (if applicable):"
    echo "  aws sso login"
    echo ""
    echo "After configuring credentials, run this script again."
    exit 1
fi

# Step 2: Navigate to backend
echo ""
echo "📁 Step 2: Navigating to backend directory..."
cd "$(dirname "$0")/backend" || {
    echo "❌ Could not find backend directory"
    exit 1
}
echo "✅ In backend directory: $(pwd)"

# Step 3: Build application
echo ""
echo "🔨 Step 3: Building SAM application..."
echo "This may take a few minutes..."
sam build --use-container --no-cached

if [ $? -ne 0 ]; then
    echo "❌ Build failed. Please check the error messages above."
    exit 1
fi
echo "✅ Build completed successfully"

# Step 4: Deploy application
echo ""
echo "🚀 Step 4: Deploying to AWS..."
echo "This will update your Lambda functions with the fixes..."
sam deploy --no-confirm-changeset --no-fail-on-empty-changeset

if [ $? -ne 0 ]; then
    echo "❌ Deployment failed. Please check the error messages above."
    echo ""
    echo "Common issues:"
    echo "  - Insufficient AWS permissions"
    echo "  - CloudFormation stack doesn't exist"
    echo "  - Region mismatch"
    echo ""
    echo "If you need help, check the AWS CloudFormation console."
    exit 1
fi

echo ""
echo "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "===================================="
echo ""
echo "✅ Fixed Issues:"
echo "  • Business photo upload during registration (no auth required)"
echo "  • WebSocket logout cleanup (removes stale connections)"
echo "  • Auth handler module path (prevents 500 errors)"
echo ""
echo "🧪 Testing Your Fixes:"
echo "  1. Try creating a new account with business photo"
echo "  2. Test user logout and check for connection cleanup"
echo "  3. Verify no more internal server errors"
echo ""
echo "🔍 If you still have issues:"
echo "  1. Wait 1-2 minutes for AWS to propagate changes"
echo "  2. Clear Flutter app cache and restart"
echo "  3. Check AWS CloudWatch logs for any errors"
echo ""
echo "📱 Your app should now work properly for new registrations!"
