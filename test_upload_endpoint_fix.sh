#!/bin/bash

# Test script to verify upload endpoint configuration
# This tests against the deployed backend (not local)

BASE_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

echo "🚀 Testing Upload Endpoint Configuration"
echo "========================================"

# Step 1: Test login to get access token
echo "📋 Step 1: Testing login to get access token..."

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
    exit 1
fi

echo "✅ Got access token: ${ACCESS_TOKEN:0:20}..."

# Step 2: Test upload endpoint exists (should not get 404)
echo ""
echo "📋 Step 2: Testing upload endpoint existence..."

# Create a simple test image (base64 encoded 1x1 pixel PNG)
TEST_IMAGE_BASE64="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="

echo "Testing /upload/product-image endpoint..."
UPLOAD_RESPONSE=$(curl -s -X POST "${BASE_URL}/upload/product-image" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -d "{
    \"image\": \"${TEST_IMAGE_BASE64}\"
  }")

echo "Upload Response:"
echo "${UPLOAD_RESPONSE}" | jq '.'

# Check response
if echo "${UPLOAD_RESPONSE}" | grep -q "missing equal sign"; then
    echo ""
    echo "❌ STILL GETTING 'missing equal sign' ERROR"
    echo "This means the upload endpoint is still not properly configured in API Gateway"
elif echo "${UPLOAD_RESPONSE}" | grep -q "404\|Not Found\|endpoint not found"; then
    echo ""
    echo "❌ UPLOAD ENDPOINT NOT FOUND (404)"
    echo "The upload endpoints were not successfully added to API Gateway"
elif echo "${UPLOAD_RESPONSE}" | grep -q "imageUrl\|success"; then
    echo ""
    echo "✅ SUCCESS: Upload endpoint is working!"
    echo "🎉 The authentication error has been fixed!"
else
    echo ""
    echo "⚠️ UNKNOWN RESPONSE"
    echo "The endpoint exists but returned an unexpected response"
fi

echo ""
echo "=========================================="
echo "🔚 Upload Endpoint Test Complete"
