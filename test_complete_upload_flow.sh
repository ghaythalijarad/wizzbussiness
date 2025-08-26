#!/bin/bash

# Test complete upload flow with provided credentials
API_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
EMAIL="g87_a@yahoo.com"
PASSWORD="Password123!"

echo "🔐 Testing complete upload flow..."
echo "API URL: $API_URL"
echo "Email: $EMAIL"
echo ""

# Step 1: Login to get access token
echo "📝 Step 1: Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/signin" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

echo "Login Response:"
echo "$LOGIN_RESPONSE" | jq '.'

# Extract access token
ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.AccessToken // empty')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
    echo "❌ Failed to get access token"
    exit 1
fi

echo ""
echo "✅ Login successful, got access token: ${ACCESS_TOKEN:0:20}..."
echo ""

# Step 2: Create a small test image (base64 encoded 1x1 PNG)
echo "📷 Step 2: Creating test image..."
# This is a base64 encoded 1x1 transparent PNG
BASE64_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="

# Step 3: Test product image upload
echo "📤 Step 3: Testing product image upload..."
UPLOAD_RESPONSE=$(curl -s -X POST "$API_URL/upload/product-image" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "{
    \"image\": \"$BASE64_IMAGE\",
    \"filename\": \"test-product-$(date +%s).png\"
  }")

echo "Upload Response:"
echo "$UPLOAD_RESPONSE" | jq '.'

# Check if upload was successful
UPLOAD_SUCCESS=$(echo "$UPLOAD_RESPONSE" | jq -r '.success // false')
IMAGE_URL=$(echo "$UPLOAD_RESPONSE" | jq -r '.imageUrl // empty')

if [ "$UPLOAD_SUCCESS" = "true" ] && [ -n "$IMAGE_URL" ]; then
    echo ""
    echo "✅ Product image upload successful!"
    echo "🖼️  Image URL: $IMAGE_URL"
    echo ""
    echo "🎉 Complete upload flow test PASSED!"
else
    echo ""
    echo "❌ Product image upload failed"
    echo "🔍 Upload response details:"
    echo "$UPLOAD_RESPONSE"
    exit 1
fi
