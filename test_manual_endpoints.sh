#!/bin/bash

# Test the lightweight tracking endpoints manually
echo "🧪 MANUAL ENDPOINT TESTING"
echo "=========================="
echo ""

# Test data
BUSINESS_ID="test_business_123"
USER_ID="test_user_456" 
EMAIL="test@example.com"
BASE_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

echo "📝 Test Data:"
echo "  Business ID: $BUSINESS_ID"
echo "  User ID: $USER_ID"
echo "  Email: $EMAIL"
echo ""

echo "🔐 Note: These tests require valid access token"
echo "   The Flutter app will provide authentication during real testing"
echo ""

echo "🎯 Testing Plan:"
echo "1. Login with business user in Flutter app"
echo "2. AppAuthService will call /auth/track-login endpoint"
echo "3. Check DynamoDB for LOGIN# entries"
echo "4. Logout from Flutter app"
echo "5. AppAuthService will call /auth/track-logout endpoint"
echo "6. Verify LOGIN# entries are removed"
echo ""

echo "Expected DynamoDB Entry Structure:"
echo "=================================="
cat << 'EOF'
{
  "PK": "LOGIN#LOGIN_test_business_123_test_user_456_<timestamp>",
  "SK": "LOGIN#LOGIN_test_business_123_test_user_456_<timestamp>",
  "connectionId": "LOGIN_test_business_123_test_user_456_<timestamp>",
  "businessId": "test_business_123",
  "userId": "test_user_456",
  "entityType": "business",
  "connectedAt": "<ISO_timestamp>",
  "ttl": <unix_timestamp_plus_1_hour>,
  "isActive": true,
  "isLoginTracking": true,
  "lastActivity": "<ISO_timestamp>",
  "GSI1PK": "BUSINESS#test_business_123",
  "GSI1SK": "LOGIN#LOGIN_test_business_123_test_user_456_<timestamp>"
}
EOF

echo ""
echo "✅ Ready for testing!"
echo "   Use the Flutter app to login and the monitoring script will show results"
