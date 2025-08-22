#!/bin/bash
set -e

echo "🧪 Testing Categories and Products Endpoints on REGIONAL API"
echo "============================================================="

API_BASE="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
EMAIL="g87_a@yahoo.com"
PASSWORD="Gha@551987"

echo "🔐 Step 1: Getting ID token..."
SIGNIN_RESPONSE=$(curl -sS -X POST \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}" \
  "${API_BASE}/auth/signin")

echo "Signin response status: $(echo "$SIGNIN_RESPONSE" | jq -r '.success // "unknown"')"

ID_TOKEN=$(echo "$SIGNIN_RESPONSE" | jq -r '.data.IdToken // empty')

if [[ -z "$ID_TOKEN" || "$ID_TOKEN" == "null" ]]; then
    echo "❌ Failed to get ID token"
    echo "Response: $SIGNIN_RESPONSE"
    exit 1
fi

echo "✅ Got ID token (length: ${#ID_TOKEN})"
echo "Token preview: ${ID_TOKEN:0:50}..."

echo ""
echo "📁 Step 2: Testing GET /categories..."
echo "Endpoint: ${API_BASE}/categories"

CATEGORIES_RESPONSE=$(curl -sS -i "${API_BASE}/categories" 2>&1 || echo "CURL_ERROR")

echo ""
echo "📋 Categories Response:"
echo "======================"
echo "$CATEGORIES_RESPONSE"

echo ""
echo "🛒 Step 3: Testing GET /products with ID token..."
echo "Endpoint: ${API_BASE}/products"
echo "Auth: Bearer ${ID_TOKEN:0:20}..."

PRODUCTS_RESPONSE=$(curl -sS -i -H "Authorization: Bearer $ID_TOKEN" \
  "${API_BASE}/products" 2>&1 || echo "CURL_ERROR")

echo ""
echo "📋 Products Response:"
echo "===================="
echo "$PRODUCTS_RESPONSE"

echo ""
echo "🔍 Step 4: Analyzing responses..."

echo "Categories endpoint (public):"
if echo "$CATEGORIES_RESPONSE" | grep -q "HTTP/2 200"; then
    echo "✅ SUCCESS: Categories endpoint returned 200"
    BODY=$(echo "$CATEGORIES_RESPONSE" | awk 'BEGIN{blank=0} blank{print} NF==0{blank=1}')
    CATEGORY_COUNT=$(echo "$BODY" | jq -r '.categories | length // 0' 2>/dev/null || echo "0")
    echo "📊 Found $CATEGORY_COUNT categories"
else
    echo "❌ FAILED: Categories endpoint failed"
fi

echo ""
echo "Products endpoint (protected):"
if echo "$PRODUCTS_RESPONSE" | grep -q "HTTP/2 200"; then
    echo "✅ SUCCESS: Products endpoint returned 200"
    BODY=$(echo "$PRODUCTS_RESPONSE" | awk 'BEGIN{blank=0} blank{print} NF==0{blank=1}')
    PRODUCT_COUNT=$(echo "$BODY" | jq -r '.products | length // 0' 2>/dev/null || echo "0")
    echo "📊 Found $PRODUCT_COUNT products"
elif echo "$PRODUCTS_RESPONSE" | grep -q "HTTP/2 403"; then
    echo "❌ FAILED: 403 Forbidden"
    echo "🔧 Issue: AWS signature validation instead of Cognito JWT"
elif echo "$PRODUCTS_RESPONSE" | grep -q "HTTP/2 401"; then
    echo "❌ FAILED: 401 Unauthorized" 
    echo "🔧 Issue: Token validation failed"
else
    echo "❌ FAILED: Unexpected response"
fi

echo ""
echo "🏁 Test complete"
