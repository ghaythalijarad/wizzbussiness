#!/bin/bash

# WebSocket Migration Discovery Script
# Finds shared WebSocket API details for migration

echo "🔍 WebSocket Migration Discovery Script"
echo "======================================"

# Check AWS CLI and profile
echo "📋 Checking AWS CLI configuration..."
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI first."
    exit 1
fi

# Set AWS profile and region
PROFILE="wizz-merchants-dev"
REGION="us-east-1"

echo "🌐 Using AWS Profile: $PROFILE"
echo "🌍 Using AWS Region: $REGION"
echo ""

# 1. Find shared WebSocket API
echo "🔍 Step 1: Finding shared WebSocket API..."
echo "----------------------------------------"

SHARED_WEBSOCKET_API=$(aws apigatewayv2 get-apis \
    --query 'Items[?Name==`WizzUser-WebSocket-dev`]' \
    --profile $PROFILE \
    --region $REGION \
    --output json)

if [ "$SHARED_WEBSOCKET_API" = "[]" ]; then
    echo "❌ Shared WebSocket API 'WizzUser-WebSocket-dev' not found!"
    echo "💡 Looking for similar WebSocket APIs..."
    
    aws apigatewayv2 get-apis \
        --query 'Items[?contains(Name, `WebSocket`) || contains(Name, `websocket`)].{ApiId:ApiId,Name:Name,CreatedDate:CreatedDate}' \
        --profile $PROFILE \
        --region $REGION \
        --output table
else
    echo "✅ Found shared WebSocket API:"
    SHARED_API_ID=$(echo $SHARED_WEBSOCKET_API | jq -r '.[0].ApiId')
    SHARED_API_NAME=$(echo $SHARED_WEBSOCKET_API | jq -r '.[0].Name')
    
    echo "   📋 API ID: $SHARED_API_ID"
    echo "   📋 API Name: $SHARED_API_NAME"
    echo "   🌐 WebSocket URL: wss://$SHARED_API_ID.execute-api.$REGION.amazonaws.com/dev"
fi
echo ""

# 2. Check shared WebSocket tables
echo "🔍 Step 2: Checking shared WebSocket tables..."
echo "--------------------------------------------"

# Check connections table
echo "📊 Checking WizzUser_websocket_connections_dev..."
CONNECTIONS_TABLE_STATUS=$(aws dynamodb describe-table \
    --table-name WizzUser_websocket_connections_dev \
    --profile $PROFILE \
    --region $REGION \
    --query 'Table.TableStatus' \
    --output text 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "✅ Connections table exists and is $CONNECTIONS_TABLE_STATUS"
    
    # Get item count
    CONNECTIONS_COUNT=$(aws dynamodb scan \
        --table-name WizzUser_websocket_connections_dev \
        --profile $PROFILE \
        --region $REGION \
        --select COUNT \
        --query 'Count' \
        --output text 2>/dev/null)
    
    echo "   📈 Current connections: $CONNECTIONS_COUNT"
else
    echo "❌ Connections table WizzUser_websocket_connections_dev not found!"
fi

# Check subscriptions table
echo "📊 Checking WizzUser_websocket_subscriptions_dev..."
SUBSCRIPTIONS_TABLE_STATUS=$(aws dynamodb describe-table \
    --table-name WizzUser_websocket_subscriptions_dev \
    --profile $PROFILE \
    --region $REGION \
    --query 'Table.TableStatus' \
    --output text 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "✅ Subscriptions table exists and is $SUBSCRIPTIONS_TABLE_STATUS"
    
    # Get item count
    SUBSCRIPTIONS_COUNT=$(aws dynamodb scan \
        --table-name WizzUser_websocket_subscriptions_dev \
        --profile $PROFILE \
        --region $REGION \
        --select COUNT \
        --query 'Count' \
        --output text 2>/dev/null)
    
    echo "   📈 Current subscriptions: $SUBSCRIPTIONS_COUNT"
else
    echo "❌ Subscriptions table WizzUser_websocket_subscriptions_dev not found!"
fi
echo ""

# 3. Check current individual WebSocket API
echo "🔍 Step 3: Checking current individual WebSocket API..."
echo "---------------------------------------------------"

CURRENT_WEBSOCKET_API=$(aws apigatewayv2 get-apis \
    --query 'Items[?contains(Name, `order-receiver-websocket`)]' \
    --profile $PROFILE \
    --region $REGION \
    --output json)

if [ "$CURRENT_WEBSOCKET_API" != "[]" ]; then
    echo "⚠️ Found current individual WebSocket API(s):"
    echo $CURRENT_WEBSOCKET_API | jq -r '.[] | "   📋 API ID: \(.ApiId), Name: \(.Name)"'
    
    CURRENT_API_ID=$(echo $CURRENT_WEBSOCKET_API | jq -r '.[0].ApiId')
    echo "   🌐 Current WebSocket URL: wss://$CURRENT_API_ID.execute-api.$REGION.amazonaws.com/dev"
else
    echo "✅ No individual WebSocket API found (already migrated?)"
fi
echo ""

# 4. Check current individual WebSocket table
echo "🔍 Step 4: Checking current individual WebSocket table..."
echo "------------------------------------------------------"

CURRENT_TABLE_STATUS=$(aws dynamodb describe-table \
    --table-name order-receiver-websocket-connections-dev \
    --profile $PROFILE \
    --region $REGION \
    --query 'Table.TableStatus' \
    --output text 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "⚠️ Found individual WebSocket table: order-receiver-websocket-connections-dev"
    echo "   📊 Status: $CURRENT_TABLE_STATUS"
    
    # Get item count
    CURRENT_COUNT=$(aws dynamodb scan \
        --table-name order-receiver-websocket-connections-dev \
        --profile $PROFILE \
        --region $REGION \
        --select COUNT \
        --query 'Count' \
        --output text 2>/dev/null)
    
    echo "   📈 Current connections: $CURRENT_COUNT"
else
    echo "✅ No individual WebSocket table found (already migrated?)"
fi
echo ""

# 5. Summary and recommendations
echo "📋 Migration Summary & Recommendations"
echo "====================================="

if [ ! -z "$SHARED_API_ID" ]; then
    echo "✅ Shared WebSocket API found: $SHARED_API_ID"
    echo "🎯 Target WebSocket URL: wss://$SHARED_API_ID.execute-api.$REGION.amazonaws.com/dev"
    echo ""
    echo "📝 Next Steps:"
    echo "1. Update CloudFormation template to remove individual WebSocket resources"
    echo "2. Update Lambda functions to use shared API: $SHARED_API_ID"
    echo "3. Update Flutter app to connect to: wss://$SHARED_API_ID.execute-api.$REGION.amazonaws.com/dev"
    echo "4. Test WebSocket connectivity with shared infrastructure"
    echo "5. Deploy migration and clean up old resources"
else
    echo "❌ Shared WebSocket API not found!"
    echo "🔧 Required Actions:"
    echo "1. Contact DevOps team to create WizzUser-WebSocket-dev API"
    echo "2. Ensure shared tables exist: WizzUser_websocket_connections_dev, WizzUser_websocket_subscriptions_dev"
    echo "3. Get proper API ID for shared WebSocket infrastructure"
fi

echo ""
echo "🎯 Migration complete when all apps use the same WebSocket infrastructure!"
