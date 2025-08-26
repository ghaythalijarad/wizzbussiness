#!/bin/bash

echo "🧪 Testing Business ID Fix"
echo "=========================="

# Test API endpoint URL
API_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

# Test credentials
EMAIL="G87_a@yahoo.com"
PASSWORD="Password123!"

echo "🔐 Step 1: Sign in and get business data"
SIGNIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/signin" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

echo "📄 Signin Response:"
echo "$SIGNIN_RESPONSE" | jq '.'

# Extract access token and business ID from response
ACCESS_TOKEN=$(echo "$SIGNIN_RESPONSE" | jq -r '.data.AccessToken // empty')
BUSINESS_ID=$(echo "$SIGNIN_RESPONSE" | jq -r '.businesses[0].businessId // empty')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
    echo "❌ Failed to get access token from signin"
    exit 1
fi

if [ -z "$BUSINESS_ID" ] || [ "$BUSINESS_ID" = "null" ]; then
    echo "❌ Failed to get business ID from signin"
    exit 1
fi

echo "✅ Access Token: ${ACCESS_TOKEN:0:20}..."
echo "✅ Business ID: $BUSINESS_ID"

echo ""
echo "🛍️ Step 2: Fetch products with this business ID"
PRODUCTS_RESPONSE=$(curl -s -X GET "$API_URL/products" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

echo "📄 Products Response:"
echo "$PRODUCTS_RESPONSE" | jq '.'

# Check if products were fetched successfully
PRODUCT_COUNT=$(echo "$PRODUCTS_RESPONSE" | jq '.products | length // 0')
SUCCESS=$(echo "$PRODUCTS_RESPONSE" | jq -r '.success // false')

echo ""
echo "📊 Results:"
echo "Success: $SUCCESS"
echo "Product Count: $PRODUCT_COUNT"

if [ "$SUCCESS" = "true" ] && [ "$PRODUCT_COUNT" -gt 0 ]; then
    echo "✅ Business ID fix successful! Products loaded correctly."
    
    echo ""
    echo "📦 Sample Products:"
    echo "$PRODUCTS_RESPONSE" | jq '.products[0:3] | .[] | {id: .productId, name: .name, businessId: .businessId}'
else
    echo "❌ Business ID fix failed. No products loaded."
    echo "Expected businessId: 7f43fe3f-3606-4ccf-9f75-1e8214c432d5"
    echo "Actual businessId from signin: $BUSINESS_ID"
fi

echo ""
echo "🏁 Test Complete"
