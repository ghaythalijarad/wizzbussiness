#!/bin/bash
set -e

echo "🧪 FINAL ADD PRODUCT ENDPOINT TEST"
echo "==================================="

API_BASE="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
EMAIL="g87_a@yahoo.com"
PASSWORD="Gha@551987"

echo "🔐 Step 1: Getting authentication tokens..."
SIGNIN_RESPONSE=$(curl -sS -X POST \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}" \
  "${API_BASE}/auth/signin")

# Extract ID token (required for Cognito User Pool authorizer)
ID_TOKEN=$(echo "$SIGNIN_RESPONSE" | jq -r '.data.IdToken // empty')

if [[ -z "$ID_TOKEN" || "$ID_TOKEN" == "null" ]]; then
    echo "❌ Failed to get ID token"
    exit 1
fi

echo "✅ Authentication successful"
echo "🔑 ID Token length: ${#ID_TOKEN}"

echo ""
echo "🛒 Step 2: Testing GET /products (verify endpoint works)..."
PRODUCTS_RESPONSE=$(curl -sS -X GET \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json" \
  "${API_BASE}/products")

echo "📋 GET Products Response:"
echo "$PRODUCTS_RESPONSE"

if echo "$PRODUCTS_RESPONSE" | jq -e '.products' >/dev/null 2>&1; then
    PRODUCT_COUNT=$(echo "$PRODUCTS_RESPONSE" | jq -r '.products | length')
    echo "✅ GET /products working! Found $PRODUCT_COUNT existing products"
    
    echo ""
    echo "🆕 Step 3: Testing POST /products (create new product)..."
    
    # Test creating a new product
    CREATE_RESPONSE=$(curl -sS -X POST \
      -H "Authorization: Bearer $ID_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "name": "Test Flutter Pizza",
        "description": "A delicious test pizza created via API to verify the add product endpoint",
        "price": 24.99,
        "categoryId": "category_restaurant_001",
        "isAvailable": true
      }' \
      "${API_BASE}/products")
    
    echo "📋 CREATE Product Response:"
    echo "$CREATE_RESPONSE"
    
    if echo "$CREATE_RESPONSE" | jq -e '.product' >/dev/null 2>&1; then
        PRODUCT_ID=$(echo "$CREATE_RESPONSE" | jq -r '.product.productId')
        PRODUCT_NAME=$(echo "$CREATE_RESPONSE" | jq -r '.product.name')
        echo ""
        echo "🎉 SUCCESS! Product created successfully!"
        echo "🆔 Product ID: $PRODUCT_ID"
        echo "📝 Product Name: $PRODUCT_NAME"
        echo ""
        echo "✅ ADD PRODUCT ENDPOINT IS WORKING PERFECTLY!"
        echo ""
        echo "🎯 Now test in Flutter app:"
        echo "1. Open the iOS Simulator"
        echo "2. Login with: $EMAIL"
        echo "3. Navigate to Add Product screen"
        echo "4. Fill the form and submit"
        echo "5. Verify success message appears"
        
    else
        echo ""
        echo "❌ Product creation failed"
        echo "Error response: $CREATE_RESPONSE"
    fi
    
else
    echo "❌ GET /products failed"
    echo "Response: $PRODUCTS_RESPONSE"
fi

echo ""
echo "🏁 API Test Complete"
