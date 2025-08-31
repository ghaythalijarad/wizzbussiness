#!/bin/bash

# Test Shared WebSocket Connectivity
# Verifies connection to WizzUser-WebSocket-dev

echo "🧪 Testing Shared WebSocket Connectivity"
echo "========================================"

# Configuration
SHARED_API_ID="lwk0wf6rpl"
SHARED_WEBSOCKET_URL="wss://lwk0wf6rpl.execute-api.us-east-1.amazonaws.com/dev"
BUSINESS_ID="business_1756220656049_ee98qktepks"

echo "🌐 Testing URL: $SHARED_WEBSOCKET_URL"
echo "🏢 Business ID: $BUSINESS_ID"
echo ""

# Check if Node.js and required modules are available
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js first."
    exit 1
fi

# Check if ws module is available
if ! node -e "require('ws')" 2>/dev/null; then
    echo "📦 Installing WebSocket module..."
    npm install ws
fi

echo "🚀 Running WebSocket connection test..."
echo "------------------------------------"

# Run the updated test
node backend/test_business_websocket.js

echo ""
echo "🎯 Test Results:"
echo "==============="
echo "✅ If connection successful: Your app can use shared WebSocket"
echo "❌ If connection failed: Check Lambda permissions and API routes"
echo ""
echo "📋 Next Steps if successful:"
echo "1. Update CloudFormation template to remove individual WebSocket API"
echo "2. Deploy updated configuration"
echo "3. Update Flutter app to use shared WebSocket URL"
echo "4. Test end-to-end functionality"

echo ""
echo "🌐 Shared WebSocket URL: $SHARED_WEBSOCKET_URL"
echo "📱 Use this URL in your Flutter app for ecosystem integration!"
