#!/bin/bash
set -e

echo "🧪 Testing Products Endpoint on REGIONAL API"
echo "=============================================="

API_BASE="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
EMAIL="g87_a@yahoo.com"
PASSWORD="Gha@551987"

echo "🔐 Step 1: Getting access token..."
SIGNIN_RESPONSE=$(curl -sS -X POST \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}" \
  "${API_BASE}/auth/signin")

echo "Signin response status: $(echo "$SIGNIN_RESPONSE" | jq -r '.success // "unknown"')"

ACCESS_TOKEN=$(echo "$SIGNIN_RESPONSE" | jq -r '.data.AccessToken // empty')

if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
    echo "❌ Failed to get access token"
    echo "Response: $SIGNIN_RESPONSE"
    exit 1
fi

echo "✅ Got access token (length: ${#ACCESS_TOKEN})"
echo "Token preview: ${ACCESS_TOKEN:0:50}..."

echo ""
echo "🛒 Step 2: Testing GET /products..."
echo "Endpoint: ${API_BASE}/products"
echo "Auth: Bearer ${ACCESS_TOKEN:0:20}..."

PRODUCTS_RESPONSE=$(curl -sS -i -H "Authorization: Bearer $ACCESS_TOKEN" \
  "${API_BASE}/products" 2>&1 || echo "CURL_ERROR")

echo ""
echo "📋 Products Response:"
echo "===================="
echo "$PRODUCTS_RESPONSE"

echo ""
echo "🔍 Step 3: Analyzing response..."

if echo "$PRODUCTS_RESPONSE" | grep -q "HTTP/2 200"; then
    echo "✅ SUCCESS: Products endpoint returned 200"
    BODY=$(echo "$PRODUCTS_RESPONSE" | awk 'BEGIN{blank=0} blank{print} NF==0{blank=1}')
    PRODUCT_COUNT=$(echo "$BODY" | jq -r '.products | length // 0' 2>/dev/null || echo "0")
    echo "📊 Found $PRODUCT_COUNT products"
elif echo "$PRODUCTS_RESPONSE" | grep -q "HTTP/2 403"; then
    echo "❌ FAILED: 403 Forbidden"
    if echo "$PRODUCTS_RESPONSE" | grep -q "Invalid key=value pair"; then
        echo "🔧 Issue: AWS signature validation instead of Cognito JWT"
        echo "This suggests API Gateway authorization configuration issue"
    fi
elif echo "$PRODUCTS_RESPONSE" | grep -q "HTTP/2 401"; then
    echo "❌ FAILED: 401 Unauthorized" 
    echo "🔧 Issue: Token validation failed"
else
    echo "❌ FAILED: Unexpected response"
fi

echo ""
echo "🏁 Test complete"
