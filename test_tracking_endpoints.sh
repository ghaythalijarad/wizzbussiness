#!/bin/bash

# Test the tracking endpoints with the correct API endpoint
API_ENDPOINT="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
EMAIL="g87_a@yahoo.com"
PASSWORD="Password1231"

echo "🧪 Testing Login Tracking Endpoints"
echo "==================================="
echo "API Endpoint: $API_ENDPOINT"
echo "Email: $EMAIL"
echo ""

# Step 1: Login to get access token
echo "1️⃣ Logging in to get access token..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_ENDPOINT/auth/signin" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

echo "Login Response:"
echo "$LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGIN_RESPONSE"
echo ""

# Extract access token
ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.accessToken // .access_token // empty' 2>/dev/null)

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo "❌ Failed to get access token from login response"
  exit 1
fi

echo "✅ Access token obtained (length: ${#ACCESS_TOKEN})"
echo ""

# Extract business info
BUSINESS_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.businesses[0].businessId // .businesses[0].id // empty' 2>/dev/null)
USER_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.user.userId // .user.sub // empty' 2>/dev/null)

echo "Business ID: $BUSINESS_ID"
echo "User ID: $USER_ID"
echo ""

# Step 2: Test track-login endpoint
echo "2️⃣ Testing track-login endpoint..."
TRACK_LOGIN_RESPONSE=$(curl -s -X POST "$API_ENDPOINT/auth/track-login" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "{
    \"businessId\": \"$BUSINESS_ID\",
    \"userId\": \"$USER_ID\",
    \"email\": \"$EMAIL\"
  }")

echo "Track Login Response:"
echo "$TRACK_LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$TRACK_LOGIN_RESPONSE"
echo ""

# Step 3: Test track-logout endpoint
echo "3️⃣ Testing track-logout endpoint..."
TRACK_LOGOUT_RESPONSE=$(curl -s -X POST "$API_ENDPOINT/auth/track-logout" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "{
    \"businessId\": \"$BUSINESS_ID\",
    \"userId\": \"$USER_ID\"
  }")

echo "Track Logout Response:"
echo "$TRACK_LOGOUT_RESPONSE" | jq '.' 2>/dev/null || echo "$TRACK_LOGOUT_RESPONSE"
echo ""

echo "✅ Tracking endpoints test completed!"
