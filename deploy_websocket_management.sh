#!/bin/bash

echo "🚀 Professional WebSocket Management System Deployment"
echo "======================================================"

# Set error handling
set -e

# Configuration
STACK_NAME="order-receiver-backend-dev"
REGION="us-east-1"
ENVIRONMENT="dev"

echo "📋 Deployment Configuration:"
echo "   Stack Name: $STACK_NAME"
echo "   Region: $REGION"
echo "   Environment: $ENVIRONMENT"
echo ""

# Change to backend directory
cd backend

echo "🔧 Step 1: Installing dependencies..."
npm install
echo "✅ Dependencies installed"
echo ""

echo "🔧 Step 2: Validating CloudFormation template..."
aws cloudformation validate-template --template-body file://template.yaml
echo "✅ Template validated successfully"
echo ""

echo "🔧 Step 3: Packaging and deploying backend..."
sam build --no-cached
sam deploy \
  --stack-name $STACK_NAME \
  --region $REGION \
  --capabilities CAPABILITY_IAM \
  --no-confirm-changeset \
  --no-fail-on-empty-changeset \
  --parameter-overrides Environment=$ENVIRONMENT
echo "✅ Backend deployed successfully"
echo ""

echo "🔧 Step 4: Retrieving deployment outputs..."
API_GATEWAY_URL=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
  --output text)

WEBSOCKET_URL=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`WebSocketUrl`].OutputValue' \
  --output text)

WEBSOCKET_CONNECTIONS_TABLE=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`WebSocketConnectionsTable`].OutputValue' \
  --output text)

echo "📊 Deployment Outputs:"
echo "   API Gateway URL: $API_GATEWAY_URL"
echo "   WebSocket URL: $WEBSOCKET_URL"
echo "   WebSocket Connections Table: $WEBSOCKET_CONNECTIONS_TABLE"
echo ""

echo "🔧 Step 5: Testing WebSocket management endpoints..."

# Test connection manager health
echo "   Testing connection manager..."
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X OPTIONS \
  -H "Content-Type: application/json" \
  "$API_GATEWAY_URL/websocket/business-connections")

if [ "$HEALTH_RESPONSE" = "204" ]; then
  echo "   ✅ Connection manager responding (CORS preflight: $HEALTH_RESPONSE)"
else
  echo "   ⚠️  Connection manager response: $HEALTH_RESPONSE"
fi

# Test business status handler
echo "   Testing business status handler..."
STATUS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X OPTIONS \
  -H "Content-Type: application/json" \
  "$API_GATEWAY_URL/businesses/test/status")

if [ "$STATUS_RESPONSE" = "200" ] || [ "$STATUS_RESPONSE" = "204" ]; then
  echo "   ✅ Business status handler responding (CORS preflight: $STATUS_RESPONSE)"
else
  echo "   ⚠️  Business status handler response: $STATUS_RESPONSE"
fi

echo ""

echo "🔧 Step 6: Verifying DynamoDB table status..."
TABLE_STATUS=$(aws dynamodb describe-table \
  --table-name $WEBSOCKET_CONNECTIONS_TABLE \
  --region $REGION \
  --query 'Table.TableStatus' \
  --output text)

if [ "$TABLE_STATUS" = "ACTIVE" ]; then
  echo "   ✅ WebSocket connections table is ACTIVE"
else
  echo "   ⚠️  WebSocket connections table status: $TABLE_STATUS"
fi

echo ""

echo "🔧 Step 7: Running connection cleanup..."
node ../cleanup_websocket_connections.js
echo "✅ Connection cleanup completed"
echo ""

echo "🎉 Professional WebSocket Management System Deployment Complete!"
echo "================================================================"
echo ""
echo "📋 System Summary:"
echo "   ✅ WebSocket Handler: Real-time connection management"
echo "   ✅ Connection Manager: Professional API endpoints"
echo "   ✅ WebSocket Service: Centralized utilities"
echo "   ✅ Business Status Handler: Online/offline management"
echo "   ✅ Authentication Integration: Login/logout tracking"
echo ""
echo "🔗 Available Endpoints:"
echo "   WebSocket URL: $WEBSOCKET_URL"
echo "   Connection Manager: $API_GATEWAY_URL/websocket/*"
echo "   Business Status: $API_GATEWAY_URL/businesses/{businessId}/status"
echo "   Auth Tracking: $API_GATEWAY_URL/auth/track-login|logout"
echo ""
echo "📊 Key Features:"
echo "   • Dual connection system (Real WebSocket + Virtual login tracking)"
echo "   • Professional stale connection cleanup"
echo "   • Comprehensive business status monitoring"
echo "   • Real-time connection heartbeat management"
echo "   • Integration with business online/offline toggle"
echo ""
echo "🎯 Next Steps:"
echo "   1. Test WebSocket connections from Flutter app"
echo "   2. Verify login/logout tracking"
echo "   3. Test online/offline status toggle"
echo "   4. Monitor connection management in CloudWatch"
echo ""
echo "Deployment completed at: $(date)"
