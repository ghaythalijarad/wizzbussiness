#!/bin/bash
set -e

echo "🧪 Testing Products Endpoint with ID Token"
echo "=========================================="

API_BASE="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
EMAIL="g87_a@yahoo.com"
PASSWORD="Gha@551987"

echo "🔐 Step 1: Getting ID token..."

# Get signin response
SIGNIN_RESPONSE=$(curl -sS -X POST \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}" \
  "${API_BASE}/auth/signin")

echo "Signin successful: $(echo "$SIGNIN_RESPONSE" | jq -r '.success // "unknown"')"

# Extract ID token (the correct token for Cognito User Pool authorizer)
ID_TOKEN=$(echo "$SIGNIN_RESPONSE" | jq -r '.data.IdToken // empty')

if [[ -z "$ID_TOKEN" || "$ID_TOKEN" == "null" ]]; then
    echo "❌ Failed to get ID token"
    echo "Response: $SIGNIN_RESPONSE"
    exit 1
fi

echo "✅ Got ID token (length: ${#ID_TOKEN})"
echo "Token preview: ${ID_TOKEN:0:50}..."

echo ""
echo "🛒 Step 2: Testing GET /products with ID token..."
echo "Endpoint: ${API_BASE}/products"

PRODUCTS_RESPONSE=$(curl -sS \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json" \
  "${API_BASE}/products")

echo ""
echo "📋 Products Response:"
echo "===================="
echo "$PRODUCTS_RESPONSE"

# Check if successful
if echo "$PRODUCTS_RESPONSE" | jq -e '.products' > /dev/null 2>&1; then
    PRODUCT_COUNT=$(echo "$PRODUCTS_RESPONSE" | jq -r '.products | length')
    echo ""
    echo "✅ SUCCESS: Products endpoint working!"
    echo "📊 Found $PRODUCT_COUNT products"
    
    # Test POST /products (create product)
    echo ""
    echo "🛒 Step 3: Testing POST /products (create product)..."
    
    CREATE_RESPONSE=$(curl -sS -X POST \
      -H "Authorization: Bearer $ID_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "name": "Test Product",
        "description": "A test product created via API",
        "price": 15.99,
        "categoryId": "category_test_001",
        "isAvailable": true
      }' \
      "${API_BASE}/products")
    
    echo "📋 Create Product Response:"
    echo "=========================="
    echo "$CREATE_RESPONSE"
    
    if echo "$CREATE_RESPONSE" | jq -e '.product' > /dev/null 2>&1; then
        echo ""
        echo "✅ SUCCESS: Product created successfully!"
        PRODUCT_ID=$(echo "$CREATE_RESPONSE" | jq -r '.product.productId')
        echo "🆔 Product ID: $PRODUCT_ID"
    else
        echo ""
        echo "❌ FAILED: Product creation failed"
        echo "Response: $CREATE_RESPONSE"
    fi
    
else
    echo ""
    echo "❌ FAILED: Products endpoint not working"
    if echo "$PRODUCTS_RESPONSE" | grep -q "Unauthorized"; then
        echo "🔧 Issue: Still getting Unauthorized - check API Gateway authorizer configuration"
    fi
fi

echo ""
echo "🏁 Test complete"
