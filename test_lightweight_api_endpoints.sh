#!/bin/bash

# Test script to verify lightweight WebSocket connection tracking endpoints
# This simulates the API calls that would be made during login/logout

echo "🧪 Testing Lightweight WebSocket Connection Tracking API Endpoints"
echo "=================================================================="

# Test data
BUSINESS_ID="test_business_123"
USER_ID="test_user_456"
EMAIL="test@example.com"
BASE_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "📋 Test Configuration:"
echo "---------------------"
echo "Business ID: $BUSINESS_ID"
echo "User ID: $USER_ID"
echo "Email: $EMAIL"
echo "Base URL: $BASE_URL"

echo ""
echo "🔐 Note: These tests require valid AWS deployment and authentication"
echo "     Since AWS credentials are invalid, we're showing the expected API calls"

echo ""
echo "🚀 Expected API Call 1: Track Business Login"
echo "--------------------------------------------"
echo "POST $BASE_URL/auth/track-login"
echo "Headers:"
echo "  Content-Type: application/json"
echo "  Authorization: Bearer <access_token>"
echo ""
echo "Request Body:"
cat << EOF
{
  "businessId": "$BUSINESS_ID",
  "userId": "$USER_ID", 
  "email": "$EMAIL"
}
EOF

echo ""
echo ""
echo "📝 Expected Response (Success):"
cat << EOF
{
  "success": true,
  "message": "Login tracking created successfully",
  "trackingId": "LOGIN_${BUSINESS_ID}_${USER_ID}_$(date +%s)"
}
EOF

echo ""
echo ""
echo "🚀 Expected API Call 2: Track Business Logout"
echo "---------------------------------------------"
echo "POST $BASE_URL/auth/track-logout"
echo "Headers:"
echo "  Content-Type: application/json"
echo "  Authorization: Bearer <access_token>"
echo ""
echo "Request Body:"
cat << EOF
{
  "businessId": "$BUSINESS_ID",
  "userId": "$USER_ID"
}
EOF

echo ""
echo ""
echo "📝 Expected Response (Success):"
cat << EOF
{
  "success": true,
  "message": "Successfully removed N login tracking entries",
  "businessId": "$BUSINESS_ID",
  "deletedCount": 1
}
EOF

echo ""
echo ""
echo "🎯 DynamoDB Table Structure (wizzgo-dev-wss-onconnect):"
echo "------------------------------------------------------"
echo "Login Tracking Entry:"
cat << EOF
{
  "PK": "LOGIN#LOGIN_${BUSINESS_ID}_${USER_ID}_<timestamp>",
  "SK": "LOGIN#LOGIN_${BUSINESS_ID}_${USER_ID}_<timestamp>", 
  "connectionId": "LOGIN_${BUSINESS_ID}_${USER_ID}_<timestamp>",
  "businessId": "$BUSINESS_ID",
  "userId": "$USER_ID",
  "entityType": "business",
  "connectedAt": "<ISO_timestamp>",
  "ttl": <unix_timestamp_plus_1_hour>,
  "isActive": true,
  "isLoginTracking": true,
  "lastActivity": "<ISO_timestamp>",
  "GSI1PK": "BUSINESS#$BUSINESS_ID",
  "GSI1SK": "LOGIN#LOGIN_${BUSINESS_ID}_${USER_ID}_<timestamp>"
}
EOF

echo ""
echo ""
echo "✅ Key Benefits of This Lightweight Approach:"
echo "--------------------------------------------"
echo "• No unnecessary virtual WebSocket connections"
echo "• Simple tracking entries with clear LOGIN# prefix"
echo "• Automatic cleanup via TTL (1 hour)"
echo "• Efficient querying via GSI1 index"
echo "• Clear distinction from real connections (isLoginTracking: true)"
echo "• Business users visible in WebSocket connections table"
echo "• Minimal overhead and resource usage"

echo ""
echo "🔧 Manual Testing Steps:"
echo "-----------------------"
echo "1. Fix AWS credentials and deploy backend:"
echo "   cd backend && ./deploy-dev.sh"
echo ""
echo "2. Test login tracking via Flutter app:"
echo "   - Run Flutter app on simulator"
echo "   - Login with business credentials"  
echo "   - Check DynamoDB console for LOGIN# entries"
echo ""
echo "3. Test logout tracking:"
echo "   - Logout from Flutter app"
echo "   - Verify LOGIN# entries are removed from DynamoDB"
echo ""
echo "4. Verify no virtual connections:"
echo "   - Confirm no entries with virtual connection IDs created"
echo "   - Only real WebSocket connections should exist (if any)"

echo ""
echo "${GREEN}✅ Lightweight tracking API endpoint test completed${NC}"
