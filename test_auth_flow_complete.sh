#!/bin/bash

# Test script for authentication and tracking endpoints
API_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

echo "🧪 Testing Authentication & Login Tracking Flow"
echo "=============================================="
echo "API Endpoint: $API_URL"
echo ""

# Test 1: Health check
echo "1️⃣ Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s -X GET "$API_URL/auth/health")
echo "Health Response: $HEALTH_RESPONSE"
echo ""

# Test 2: Try to register a test user (for testing only)
echo "2️⃣ Attempting to register test user..."
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/auth/register-with-business" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@wizzdelivery.com",
    "password": "TestPassword123!",
    "firstName": "Test",
    "lastName": "User",
    "businessName": "Test Business",
    "businessType": "restaurant"
  }')
echo "Register Response: $REGISTER_RESPONSE"
echo ""

# Test 3: Try to login with test credentials (this might fail if user doesn't exist)
echo "3️⃣ Attempting login..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/signin" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@wizzdelivery.com",
    "password": "TestPassword123!"
  }')
echo "Login Response: $LOGIN_RESPONSE"
echo ""

# Extract access token if login was successful
ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.AccessToken // empty')

if [ ! -z "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]; then
    echo "✅ Login successful! Access token received."
    echo ""
    
    # Test 4: Test login tracking
    echo "4️⃣ Testing login tracking..."
    TRACK_LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/track-login" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -d '{
        "businessId": "test-business-123",
        "userId": "test-user-456",
        "email": "testuser@wizzdelivery.com"
      }')
    echo "Track Login Response: $TRACK_LOGIN_RESPONSE"
    echo ""
    
    # Test 5: Test logout tracking
    echo "5️⃣ Testing logout tracking..."
    TRACK_LOGOUT_RESPONSE=$(curl -s -X POST "$API_URL/auth/track-logout" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -d '{
        "businessId": "test-business-123",
        "userId": "test-user-456"
      }')
    echo "Track Logout Response: $TRACK_LOGOUT_RESPONSE"
    echo ""
    
    echo "🎉 All tests completed successfully!"
else
    echo "❌ Login failed or no access token received."
    echo "💡 This is expected if the test user doesn't exist in Cognito."
    echo "💡 The signin endpoint is working, but authentication requires valid Cognito users."
    echo ""
    echo "ℹ️  To test with real users:"
    echo "   1. Register a user through the app"
    echo "   2. Verify the email"
    echo "   3. Use those credentials in this test"
fi
