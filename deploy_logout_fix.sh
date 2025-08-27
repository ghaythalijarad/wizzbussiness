#!/bin/bash

echo "🚀 Deploying WebSocket Logout Cleanup Fix"
echo "=========================================="

cd backend

echo "📦 Building and deploying the auth function with WebSocket service fix..."

# Deploy just the auth function with the fix
sam build --use-container --no-cached
sam deploy --no-confirm-changeset --no-fail-on-empty-changeset

echo "✅ Deployment completed!"
echo ""
echo "🧪 Next steps:"
echo "1. Test the logout endpoint with authentication"
echo "2. Verify WebSocket connections are cleaned up properly"
echo "3. Monitor for any remaining issues"
