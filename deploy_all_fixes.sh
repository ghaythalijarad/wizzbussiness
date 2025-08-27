#!/bin/bash

echo "🚀 Deploying Business Photo Upload Fix & WebSocket Logout Cleanup"
echo "================================================================="

# Check if AWS credentials are working
echo "🔐 Checking AWS credentials..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS credentials are invalid or expired."
    echo ""
    echo "🔧 Please configure AWS credentials first:"
    echo "   Option 1: aws configure"
    echo "   Option 2: aws sso login"
    echo "   Option 3: Set environment variables:"
    echo "           export AWS_ACCESS_KEY_ID=your_access_key"
    echo "           export AWS_SECRET_ACCESS_KEY=your_secret_key"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "✅ AWS credentials are valid"

# Navigate to backend directory
cd "$(dirname "$0")/backend" || exit 1

echo ""
echo "📦 Building SAM application..."
sam build --use-container --no-cached

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "🚀 Deploying to AWS..."
sam deploy --no-confirm-changeset --no-fail-on-empty-changeset

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment completed successfully!"
    echo ""
    echo "🎯 What's been fixed:"
    echo "   ✅ Business photo upload during registration (no auth required)"
    echo "   ✅ WebSocket logout cleanup (removes stale connections)"
    echo "   ✅ Auth handler module path fixed"
    echo ""
    echo "🧪 Next steps:"
    echo "   1. Test business registration with photo upload"
    echo "   2. Test user logout and verify WebSocket cleanup"
    echo "   3. Monitor for any remaining issues"
    echo ""
    echo "📱 Try creating a new account now - photo upload should work!"
else
    echo ""
    echo "❌ Deployment failed"
    echo "Please check the error message above and try again"
    exit 1
fi
