#!/bin/bash
set -e

echo "🧪 Testing Products Endpoint Authentication Flow"
echo "================================================"

API_BASE="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
EMAIL="g87_a@yahoo.com"
PASSWORD="Gha@551987"

echo "🔐 Step 1: Authenticating user..."
SIGNIN_RESPONSE=$(curl -sS -X POST "$API_BASE/auth/signin" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

echo "Authentication response:"
echo "$SIGNIN_RESPONSE" | jq '.'
echo

# Extract tokens correctly
ACCESS_TOKEN=$(echo "$SIGNIN_RESPONSE" | jq -r '.data.AccessToken')
ID_TOKEN=$(echo "$SIGNIN_RESPONSE" | jq -r '.data.IdToken')

if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
    echo "❌ Failed to get access token"
    exit 1
fi

if [[ -z "$ID_TOKEN" || "$ID_TOKEN" == "null" ]]; then
    echo "❌ Failed to get ID token"
    exit 1
fi

echo "✅ Got Access Token (${#ACCESS_TOKEN} chars)"
echo "✅ Got ID Token (${#ID_TOKEN} chars)"
echo

# Test with Access Token (should fail)
echo "🔍 Step 2: Testing with Access Token (expecting failure)..."
ACCESS_RESPONSE=$(curl -sS -X GET "$API_BASE/products" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json")

echo "Access Token Response:"
echo "$ACCESS_RESPONSE" | jq '.' 2>/dev/null || echo "$ACCESS_RESPONSE"
echo

# Test with ID Token (should succeed)
echo "🔍 Step 3: Testing with ID Token (expecting success)..."
ID_RESPONSE=$(curl -sS -X GET "$API_BASE/products" \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json")

echo "ID Token Response:"
echo "$ID_RESPONSE" | jq '.' 2>/dev/null || echo "$ID_RESPONSE"

# Check if ID token test was successful
if echo "$ID_RESPONSE" | jq -e '.products' >/dev/null 2>&1; then
    echo
    echo "🎉 SUCCESS! ID Token authentication working correctly!"
    echo "✅ Products endpoint accessible with ID Token"
    echo "✅ Authentication flow is working end-to-end"
elif echo "$ID_RESPONSE" | jq -e '.message' >/dev/null 2>&1; then
    MESSAGE=$(echo "$ID_RESPONSE" | jq -r '.message')
    if [[ "$MESSAGE" == "Unauthorized" ]]; then
        echo
        echo "❌ FAILURE! ID Token still returning Unauthorized"
        echo "The backend fix may not have been deployed correctly"
        exit 1
    else
        echo
        echo "⚠️  Unexpected response: $MESSAGE"
        exit 1
    fi
else
    echo
    echo "❌ FAILURE! Unexpected response format"
    exit 1
fi
