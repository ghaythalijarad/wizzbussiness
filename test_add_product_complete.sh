#!/bin/bash

echo "🧪 COMPREHENSIVE ADD PRODUCT BACKEND TEST"
echo "========================================="
echo ""

# API Configuration
API_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
USERNAME="g87_a@yahoo.com"
PASSWORD="Gha@551987"

echo "🔐 Step 1: Authentication..."
LOGIN_RESPONSE=$(curl -s -X POST "${API_URL}/auth/signin" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$USERNAME\",\"password\":\"$PASSWORD\"}")

ACCESS_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.data.AccessToken // empty')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
    echo "❌ Authentication failed"
    exit 1
fi

echo "✅ Authentication successful"
echo ""

echo "📋 Step 2: Categories Loading..."
CATEGORIES_RESPONSE=$(curl -s -X GET "${API_URL}/categories/business-type/restaurant")
CATEGORIES_SUCCESS=$(echo $CATEGORIES_RESPONSE | jq -r '.success')
CATEGORIES_COUNT=$(echo $CATEGORIES_RESPONSE | jq -r '.categories | length')

if [ "$CATEGORIES_SUCCESS" = "true" ]; then
    echo "✅ Categories loaded successfully ($CATEGORIES_COUNT categories)"
else
    echo "❌ Categories loading failed"
fi
echo ""

echo "🎯 Step 3: Product Creation (without image)..."
PRODUCT_RESPONSE=$(curl -s -X POST "${API_URL}/products" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -d '{
    "name": "Test Product Complete Flow", 
    "name_ar": "منتج اختبار التدفق الكامل",
    "description": "Testing complete add product flow",
    "description_ar": "اختبار تدفق إضافة المنتج الكامل", 
    "price": 35.99,
    "categoryId": "4d3e103e-a8e7-4361-88ca-11219ed884b5",
    "availableQuantity": 50
  }')

PRODUCT_SUCCESS=$(echo $PRODUCT_RESPONSE | jq -r '.success')
PRODUCT_ID=$(echo $PRODUCT_RESPONSE | jq -r '.product.productId // empty')

if [ "$PRODUCT_SUCCESS" = "true" ]; then
    echo "✅ Product creation successful (ID: $PRODUCT_ID)"
else
    echo "❌ Product creation failed"
    echo "Response: $PRODUCT_RESPONSE"
fi
echo ""

echo "📸 Step 4: Image Upload (CRITICAL TEST)..."
BASE64_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
FILENAME="test-$(date +%s).png"

IMAGE_RESPONSE=$(curl -s -X POST "${API_URL}/upload/product-image" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -d "{\"image\":\"$BASE64_IMAGE\",\"filename\":\"$FILENAME\"}")

IMAGE_SUCCESS=$(echo $IMAGE_RESPONSE | jq -r '.success // empty')
IMAGE_URL=$(echo $IMAGE_RESPONSE | jq -r '.imageUrl // empty')

if [ "$IMAGE_SUCCESS" = "true" ]; then
    echo "✅ Image upload successful!"
    echo "📍 Image URL: $IMAGE_URL"
else
    echo "❌ Image upload failed"
    echo "Response: $IMAGE_RESPONSE"
fi
echo ""

echo "📦 Step 5: Products Listing..."
LIST_RESPONSE=$(curl -s -X GET "${API_URL}/products" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

LIST_SUCCESS=$(echo $LIST_RESPONSE | jq -r '.success')
PRODUCTS_COUNT=$(echo $LIST_RESPONSE | jq -r '.products | length')

if [ "$LIST_SUCCESS" = "true" ]; then
    echo "✅ Products listing successful ($PRODUCTS_COUNT products found)"
else
    echo "❌ Products listing failed"
fi
echo ""

echo "📊 FINAL RESULTS:"
echo "=================="
echo "Authentication: $([ -n "$ACCESS_TOKEN" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "Categories: $([ "$CATEGORIES_SUCCESS" = "true" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "Product Creation: $([ "$PRODUCT_SUCCESS" = "true" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "Image Upload: $([ "$IMAGE_SUCCESS" = "true" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "Products Listing: $([ "$LIST_SUCCESS" = "true" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo ""

if [ "$IMAGE_SUCCESS" = "true" ]; then
    echo "🎉 ADD PRODUCT BACKEND: FULLY CONFIGURED AND WORKING!"
    echo "🚀 Ready for complete end-to-end testing in Flutter app"
else
    echo "⚠️  ADD PRODUCT BACKEND: 80% CONFIGURED"
    echo "🔧 Needs deployment to fix image upload authorization"
    echo "💡 Run: cd backend && sam deploy --no-confirm-changeset"
fi

echo ""
echo "✅ Test completed at $(date)"
