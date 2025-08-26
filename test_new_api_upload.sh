#!/bin/bash

# Test the FIXED upload endpoints with NEW API Gateway
API_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
TEST_EMAIL="g87_a@yahoo.com"
TEST_PASSWORD="Password123!"

echo "🚀 Testing FIXED Upload Endpoints - NEW API Gateway"
echo "=================================================="
echo "🔗 API URL: $API_URL"
echo ""

# Step 1: Login to get access token
echo "📋 Step 1: Testing login to get access token..."
LOGIN_RESPONSE=$(curl -s -X POST "${API_URL}/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${TEST_EMAIL}\",
    \"password\": \"${TEST_PASSWORD}\"
  }")

echo "Login Response:"
echo "$LOGIN_RESPONSE" | jq '.'

# Extract access token
ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.AccessToken // empty')
if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
    echo "❌ Failed to get access token"
    exit 1
fi

echo "✅ Got access token: ${ACCESS_TOKEN:0:20}..."
echo ""

# Step 2: Test image upload (this should now work!)
echo "📋 Step 2: Testing image upload to FIXED API Gateway..."

# Create a simple base64 test image (1x1 red pixel PNG)
TEST_IMAGE_BASE64="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="

UPLOAD_RESPONSE=$(curl -s -X POST "${API_URL}/upload/product-image" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -d "{
    \"image\": \"${TEST_IMAGE_BASE64}\",
    \"filename\": \"test-product-fixed.png\"
  }")

echo "Image Upload Response:"
echo "$UPLOAD_RESPONSE" | jq '.' 2>/dev/null || echo "$UPLOAD_RESPONSE"

# Check if upload was successful
if echo "$UPLOAD_RESPONSE" | jq -e '.success' >/dev/null 2>&1; then
    echo "🎉 SUCCESS! Image upload is now working!"
    IMAGE_URL=$(echo "$UPLOAD_RESPONSE" | jq -r '.imageUrl')
    echo "🖼️  Image URL: $IMAGE_URL"
    
    # Step 3: Test complete product creation with image
    echo ""
    echo "📋 Step 3: Testing complete product creation with image..."
    
    CREATE_PRODUCT_RESPONSE=$(curl -s -X POST "${API_URL}/products" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${ACCESS_TOKEN}" \
      -d "{
        \"name\": \"Test Product FIXED\",
        \"name_ar\": \"منتج تجريبي محدث\",
        \"description\": \"A test product created with FIXED image upload\",
        \"description_ar\": \"منتج تجريبي تم إنشاؤه مع رفع الصورة المحدث\",
        \"price\": 25.99,
        \"category\": \"Main Courses\",
        \"category_ar\": \"الأطباق الرئيسية\",
        \"availableQuantity\": 15,
        \"imageUrl\": \"${IMAGE_URL}\"
      }")
    
    echo "Product Creation Response:"
    echo "$CREATE_PRODUCT_RESPONSE" | jq '.' 2>/dev/null || echo "$CREATE_PRODUCT_RESPONSE"
    
    if echo "$CREATE_PRODUCT_RESPONSE" | jq -e '.success' >/dev/null 2>&1; then
        echo "🎉 COMPLETE SUCCESS! The upload endpoints fix is working perfectly!"
        echo "✅ The 'Invalid key=value pair (missing equal-sign) in Authorization header' error is FIXED!"
    else
        echo "✅ Image upload now works! Product creation may need separate attention."
    fi
    
else
    echo "❌ Image upload still failing. Response:"
    echo "$UPLOAD_RESPONSE"
    
    # Check for specific error messages
    if echo "$UPLOAD_RESPONSE" | grep -q "Invalid key=value pair"; then
        echo ""
        echo "⚠️  Still getting the original error - upload endpoints may not be deployed correctly"
    elif echo "$UPLOAD_RESPONSE" | grep -q "Unauthorized"; then
        echo ""
        echo "⚠️  Getting Unauthorized - this is progress! Endpoint exists but auth issue"
    elif echo "$UPLOAD_RESPONSE" | grep -q "Missing Authentication Token"; then
        echo ""
        echo "⚠️  Endpoint may not exist in this API Gateway"
    fi
fi

echo ""
echo "🏁 Upload endpoints fix test completed!"
