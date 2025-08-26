#!/bin/bash

# Test script to verify backend upload endpoint works with Flutter app format
# This simulates exactly what the Flutter app sends

echo "🧪 Testing Backend Upload with Flutter App Format..."

# API Gateway endpoint
API_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

# Test credentials (replace with valid ones)
USERNAME="ghaythal.laheebi@gmail.com"
PASSWORD="testing123456"

echo "🔐 Getting authentication token..."

# Get access token
AUTH_RESPONSE=$(curl -s -X POST \
  "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"$USERNAME\",
    \"password\": \"$PASSWORD\"
  }")

echo "Auth response: $AUTH_RESPONSE"

ACCESS_TOKEN=$(echo $AUTH_RESPONSE | jq -r '.accessToken')

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Failed to get access token"
  exit 1
fi

echo "✅ Got access token: ${ACCESS_TOKEN:0:20}..."

# Create a small test image as base64 (1x1 pixel PNG)
# This is the smallest valid PNG file possible
BASE64_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="

# Test filename with UUID format (similar to Flutter app)
FILENAME="test-$(uuidgen | tr '[:upper:]' '[:lower:]').png"

echo "�� Testing product image upload with Flutter format..."

# Upload request exactly like Flutter app
UPLOAD_RESPONSE=$(curl -s -X POST \
  "$API_URL/upload/product-image" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "{
    \"image\": \"$BASE64_IMAGE\",
    \"filename\": \"$FILENAME\"
  }")

echo "Upload response: $UPLOAD_RESPONSE"

# Check if upload was successful
SUCCESS=$(echo $UPLOAD_RESPONSE | jq -r '.success')
IMAGE_URL=$(echo $UPLOAD_RESPONSE | jq -r '.imageUrl')

if [ "$SUCCESS" = "true" ]; then
  echo "✅ Product image upload successful!"
  echo "📍 Image URL: $IMAGE_URL"
  
  # Test if the image is accessible
  echo "🔍 Testing image accessibility..."
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$IMAGE_URL")
  
  if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Image is accessible via URL"
  else
    echo "⚠️  Image URL returned status: $HTTP_STATUS"
  fi
  
else
  echo "❌ Product image upload failed"
  MESSAGE=$(echo $UPLOAD_RESPONSE | jq -r '.message')
  echo "Error message: $MESSAGE"
fi

echo "🏁 Test completed"
