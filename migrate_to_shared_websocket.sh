#!/bin/bash

# WebSocket Migration Implementation Script
# Migrates from individual WebSocket API to shared WizzUser-WebSocket-dev

echo "🚀 WebSocket Migration to Shared Infrastructure"
echo "=============================================="

# Configuration
SHARED_API_ID="lwk0wf6rpl"
SHARED_WEBSOCKET_URL="wss://lwk0wf6rpl.execute-api.us-east-1.amazonaws.com/dev"
CURRENT_API_ID="zym5y430ce"
CURRENT_WEBSOCKET_URL="wss://zym5y430ce.execute-api.us-east-1.amazonaws.com/dev"

echo "📋 Migration Configuration:"
echo "  🎯 Target (Shared): $SHARED_WEBSOCKET_URL"
echo "  📍 Current (Individual): $CURRENT_WEBSOCKET_URL"
echo ""

# Step 1: Update CloudFormation template
echo "🔧 Step 1: Updating CloudFormation template..."
echo "----------------------------------------------"

# Backup original template
cp backend/template.yaml backend/template.yaml.backup
echo "✅ Backed up original template to template.yaml.backup"

# Step 2: Update Flutter app configuration
echo "🔧 Step 2: Updating Flutter app configuration..."
echo "-----------------------------------------------"

# Update any hardcoded WebSocket URLs in Flutter
find frontend -name "*.dart" -type f -exec grep -l "wss://" {} \; | while read file; do
    if grep -q "$CURRENT_API_ID" "$file"; then
        echo "⚠️ Found WebSocket URL in: $file"
        echo "   Please manually update to use shared API: $SHARED_API_ID"
    fi
done

# Step 3: Update test files
echo "🔧 Step 3: Updating test files..."
echo "--------------------------------"

# Update test_business_websocket.js
if [ -f "backend/test_business_websocket.js" ]; then
    sed -i.backup "s|wss://.*execute-api|wss://$SHARED_API_ID.execute-api|g" backend/test_business_websocket.js
    echo "✅ Updated backend/test_business_websocket.js"
fi

# Update any other test files
find . -name "*websocket*test*.js" -type f | while read file; do
    if grep -q "$CURRENT_API_ID" "$file"; then
        sed -i.backup "s|$CURRENT_API_ID|$SHARED_API_ID|g" "$file"
        echo "✅ Updated $file"
    fi
done

echo ""
echo "🎯 Migration Steps Completed!"
echo "============================="
echo ""
echo "📝 Manual Steps Required:"
echo "1. Review and deploy updated CloudFormation template"
echo "2. Update Lambda function permissions for shared API"
echo "3. Test WebSocket connectivity with shared infrastructure"
echo "4. Update Flutter app WebSocket URLs"
echo "5. Deploy and verify functionality"
echo ""
echo "🌐 New WebSocket URL: $SHARED_WEBSOCKET_URL"
echo "📋 Shared API ID: $SHARED_API_ID"
