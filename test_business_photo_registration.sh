#!/bin/bash

echo "🧪 Testing Business Photo Upload Authorization During Registration"
echo "=================================================================="
echo ""

API_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

# Create a small test image as base64 (1x1 pixel PNG)
BASE64_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="

# Test filename with UUID format (similar to Flutter app)
FILENAME="business-photo-$(uuidgen | tr '[:upper:]' '[:lower:]').jpg"

echo "📤 Testing business photo upload WITHOUT authentication (registration flow)..."

# Upload request with registration header (no auth token needed)
UPLOAD_RESPONSE=$(curl -s -X POST \
  "$API_URL/upload/business-photo" \
  -H "Content-Type: application/json" \
  -H "X-Registration-Upload: true" \
  -d "{
    \"image\": \"$BASE64_IMAGE\",
    \"filename\": \"$FILENAME\"
  }")

echo "Upload response: $UPLOAD_RESPONSE"

# Check if upload was successful
SUCCESS=$(echo $UPLOAD_RESPONSE | jq -r '.success' 2>/dev/null)
IMAGE_URL=$(echo $UPLOAD_RESPONSE | jq -r '.imageUrl' 2>/dev/null)

if [ "$SUCCESS" = "true" ]; then
  echo "✅ Business photo upload successful during registration!"
  echo "📍 Image URL: $IMAGE_URL"
  echo ""
  echo "🎉 AUTHORIZATION BYPASS WORKING!"
  echo "The business photo upload authorization fix is working properly."
  
else
  echo "❌ Business photo upload failed"
  MESSAGE=$(echo $UPLOAD_RESPONSE | jq -r '.message' 2>/dev/null)
  echo "Error message: $MESSAGE"
  echo ""
  echo "🚨 AUTHORIZATION BYPASS NOT DEPLOYED YET"
  echo "Need to deploy the backend fix to resolve this issue."
fi

echo ""
echo "🏁 Test completed"
