#!/bin/bash

# Test script to add a product with image directly via backend API
# This will help isolate if the issue is in frontend auth or backend processing

BASE_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

echo "🚀 Testing Add Product with Image via Backend API"
echo "=================================================="

# Step 1: Test login to get access token
echo "📋 Step 1: Testing login to get access token..."

# Valid test credentials found in the codebase
TEST_EMAIL="g87_a@yahoo.com"
TEST_PASSWORD="Password123!"

LOGIN_RESPONSE=$(curl -s -X POST "${BASE_URL}/auth/signin" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${TEST_EMAIL}\",
    \"password\": \"${TEST_PASSWORD}\"
  }")

echo "Login Response:"
echo "${LOGIN_RESPONSE}" | jq '.'

# Extract access token
ACCESS_TOKEN=$(echo "${LOGIN_RESPONSE}" | jq -r '.data.AccessToken // empty')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
    echo "❌ Failed to get access token. Login may have failed."
    echo "Please check credentials or create a test user first."
    exit 1
fi

echo "✅ Got access token: ${ACCESS_TOKEN:0:20}..."

# Step 2: Test uploading an image first
echo ""
echo "📋 Step 2: Testing image upload..."

# Create a simple test image (base64 encoded 1x1 pixel PNG)
TEST_IMAGE_BASE64="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="

IMAGE_UPLOAD_RESPONSE=$(curl -s -X POST "${BASE_URL}/upload/product-image" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -d "{
    \"image\": \"${TEST_IMAGE_BASE64}\"
  }")

echo "Image Upload Response:"
echo "${IMAGE_UPLOAD_RESPONSE}" | jq '.'

# Extract image URL
IMAGE_URL=$(echo "${IMAGE_UPLOAD_RESPONSE}" | jq -r '.imageUrl // empty')

if [ -z "$IMAGE_URL" ] || [ "$IMAGE_URL" = "null" ]; then
    echo "❌ Failed to upload image. Response:"
    echo "${IMAGE_UPLOAD_RESPONSE}"
    exit 1
fi

echo "✅ Got image URL: ${IMAGE_URL}"

# Step 3: Get categories to use a valid category ID
echo ""
echo "📋 Step 3: Getting categories..."

CATEGORIES_RESPONSE=$(curl -s -X GET "${BASE_URL}/categories/business-type/restaurant" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

echo "Categories Response:"
echo "${CATEGORIES_RESPONSE}" | jq '.'

# Extract first category ID
CATEGORY_ID=$(echo "${CATEGORIES_RESPONSE}" | jq -r '.categories[0].categoryId // empty')

if [ -z "$CATEGORY_ID" ] || [ "$CATEGORY_ID" = "null" ]; then
    echo "❌ Failed to get category ID"
    exit 1
fi

echo "✅ Using category ID: ${CATEGORY_ID}"

# Step 4: Test creating product with uploaded image
echo ""
echo "📋 Step 4: Testing product creation with image..."

PRODUCT_DATA=$(cat <<EOF
{
  "name": "Test Product with Image",
  "description": "This is a test product created via backend API with an uploaded image",
  "price": 12.99,
  "categoryId": "${CATEGORY_ID}",
  "imageUrl": "${IMAGE_URL}",
  "isAvailable": true
}
EOF
)

echo "Product data to send:"
echo "${PRODUCT_DATA}" | jq '.'

PRODUCT_RESPONSE=$(curl -s -X POST "${BASE_URL}/products" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -d "${PRODUCT_DATA}")

echo ""
echo "Product Creation Response:"
echo "${PRODUCT_RESPONSE}" | jq '.'

# Check if product was created successfully
PRODUCT_SUCCESS=$(echo "${PRODUCT_RESPONSE}" | jq -r '.success // false')

if [ "$PRODUCT_SUCCESS" = "true" ]; then
    echo ""
    echo "✅ SUCCESS: Product created successfully with image!"
    echo "🎉 Backend API is working correctly for product creation with images"
    
    PRODUCT_ID=$(echo "${PRODUCT_RESPONSE}" | jq -r '.product.id // .product.productId // empty')
    if [ ! -z "$PRODUCT_ID" ] && [ "$PRODUCT_ID" != "null" ]; then
        echo "📦 Created Product ID: ${PRODUCT_ID}"
    fi
else
    echo ""
    echo "❌ FAILED: Product creation failed"
    echo "Error details:"
    echo "${PRODUCT_RESPONSE}" | jq '.'
    
    # Check for specific authentication errors
    if echo "${PRODUCT_RESPONSE}" | grep -q "missing equal sign\|authentication\|unauthorized"; then
        echo ""
        echo "🔍 AUTHENTICATION ERROR DETECTED!"
        echo "This suggests the issue is with authentication header parsing"
    fi
fi

echo ""
echo "=================================================="
echo "🔚 Backend API Test Complete"
