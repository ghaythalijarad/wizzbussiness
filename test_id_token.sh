#!/bin/bash

# Test script to verify ID token works with API Gateway
# This script will extract the ID token from authentication and test the /products endpoint

set -e

API_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
EMAIL="g87_a@yahoo.com"
PASSWORD="Test123!"

echo "🔐 Testing ID Token Authentication for API Gateway"
echo "=================================================="

# Step 1: Authenticate and get tokens
echo "📡 Step 1: Authenticating with email: $EMAIL"
AUTH_RESPONSE=$(curl -s -X POST "$API_URL/auth/signin" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

echo "📋 Auth Response: $AUTH_RESPONSE"

# Extract tokens using jq if available, otherwise use basic parsing
if command -v jq &> /dev/null; then
    ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.data.AccessToken // empty')
    ID_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.data.IdToken // empty')
else
    # Basic extraction without jq
    ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"AccessToken":"[^"]*' | cut -d'"' -f4)
    ID_TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"IdToken":"[^"]*' | cut -d'"' -f4)
fi

if [ -z "$ID_TOKEN" ]; then
    echo "❌ Failed to extract ID token from auth response"
    exit 1
fi

echo "✅ Tokens extracted successfully"
echo "📏 Access Token length: ${#ACCESS_TOKEN}"
echo "📏 ID Token length: ${#ID_TOKEN}"

# Step 2: Test with Access Token (should fail)
echo ""
echo "📡 Step 2: Testing /products with Access Token (should fail)"
ACCESS_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" -X GET "$API_URL/products" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json")

ACCESS_HTTP_CODE=$(echo "$ACCESS_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
ACCESS_BODY=$(echo "$ACCESS_RESPONSE" | sed -E 's/HTTPSTATUS:[0-9]{3}$//')

echo "📋 Access Token Response Code: $ACCESS_HTTP_CODE"
echo "📋 Access Token Response Body: $ACCESS_BODY"

# Step 3: Test with ID Token (should succeed)
echo ""
echo "📡 Step 3: Testing /products with ID Token (should succeed)"
ID_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" -X GET "$API_URL/products" \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json")

ID_HTTP_CODE=$(echo "$ID_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
ID_BODY=$(echo "$ID_RESPONSE" | sed -E 's/HTTPSTATUS:[0-9]{3}$//')

echo "📋 ID Token Response Code: $ID_HTTP_CODE"
echo "📋 ID Token Response Body: $ID_BODY"

# Step 4: Summary
echo ""
echo "📊 SUMMARY"
echo "=========="
echo "Access Token Result: HTTP $ACCESS_HTTP_CODE"
echo "ID Token Result: HTTP $ID_HTTP_CODE"

if [ "$ID_HTTP_CODE" = "200" ]; then
    echo "🎉 SUCCESS! ID Token authentication works!"
    echo "✅ The fix is working correctly"
elif [ "$ACCESS_HTTP_CODE" = "200" ]; then
    echo "⚠️  Access Token worked instead of ID Token"
    echo "🔧 May need to check API Gateway configuration"
else
    echo "❌ Both tokens failed - may need further investigation"
fi

echo ""
echo "💡 For API Gateway Cognito User Pool authorizers:"
echo "   - Use ID Token (token_use: 'id') ✅"
echo "   - Not Access Token (token_use: 'access') ❌"
