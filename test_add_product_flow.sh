#!/bin/bash

echo "📱 TESTING ADD PRODUCT FUNCTIONALITY"
echo "===================================="
echo ""

# Configuration
API_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
EMAIL="g87_a@yahoo.com"
PASSWORD="Gha@551987"

echo "🔐 Step 1: Authenticating user..."
echo "Email: $EMAIL"
echo ""

# Login to get access token
LOGIN_RESPONSE=$(curl -s -X POST \
  "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

echo "Login response: $LOGIN_RESPONSE"
echo ""

# Extract access token
ACCESS_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.tokens.access_token' 2>/dev/null)

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Failed to get access token"
  echo "Login response: $LOGIN_RESPONSE"
  exit 1
fi

echo "✅ Got access token: ${ACCESS_TOKEN:0:20}..."
echo ""

# Test 1: Create a small test image as base64 (1x1 pixel PNG)
BASE64_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
FILENAME="test-product-$(uuidgen | tr '[:upper:]' '[:lower:]').png"

echo "📤 Step 2: Testing product image upload..."
echo "Filename: $FILENAME"
echo ""

# Test product image upload
UPLOAD_RESPONSE=$(curl -s -X POST \
  "$API_URL/upload/product-image" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "{
    \"image\": \"$BASE64_IMAGE\",
    \"filename\": \"$FILENAME\"
  }")

echo "Upload response: $UPLOAD_RESPONSE"
echo ""

# Check if upload was successful
UPLOAD_SUCCESS=$(echo $UPLOAD_RESPONSE | jq -r '.success' 2>/dev/null)
IMAGE_URL=$(echo $UPLOAD_RESPONSE | jq -r '.imageUrl' 2>/dev/null)

if [ "$UPLOAD_SUCCESS" = "true" ]; then
  echo "✅ Image upload successful!"
  echo "Image URL: $IMAGE_URL"
  echo ""
  
  echo "🛍️ Step 3: Testing product creation..."
  
  # Test product creation
  PRODUCT_RESPONSE=$(curl -s -X POST \
    "$API_URL/products" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d "{
      \"name\": \"Test Product $(date +%s)\",
      \"description\": \"Test product for backend functionality\",
      \"price\": 25.99,
      \"category\": \"Food\",
      \"imageUrl\": \"$IMAGE_URL\",
      \"isAvailable\": true
    }")
  
  echo "Product creation response: $PRODUCT_RESPONSE"
  echo ""
  
  # Check if product creation was successful
  PRODUCT_SUCCESS=$(echo $PRODUCT_RESPONSE | jq -r '.success' 2>/dev/null)
  
  if [ "$PRODUCT_SUCCESS" = "true" ]; then
    echo "🎉 SUCCESS! Complete add product flow working!"
    echo ""
    echo "📊 SUMMARY:"
    echo "✅ Authentication: Working"
    echo "✅ Image Upload: Working"
    echo "✅ Product Creation: Working"
  else
    echo "❌ Product creation failed"
    echo "Response: $PRODUCT_RESPONSE"
  fi
  
else
  echo "❌ Image upload failed"
  echo "Response: $UPLOAD_RESPONSE"
  
  # Check if it's an authorization error
  if echo "$UPLOAD_RESPONSE" | grep -q "401\|Unauthorized\|Invalid.*Authorization"; then
    echo ""
    echo "🔍 AUTHORIZATION ERROR DETECTED"
    echo "Let's debug the authorization header..."
    
    # Test the exact header format
    echo ""
    echo "Testing different authorization header formats:"
    
    # Test 1: Standard Bearer format
    echo "Test 1: Standard Bearer format"
    curl -s -X POST \
      "$API_URL/upload/product-image" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -d "{\"image\": \"$BASE64_IMAGE\", \"filename\": \"$FILENAME\"}" \
      -w "HTTP Status: %{http_code}\n" | head -2
    
    echo ""
    
    # Test 2: Check token format
    echo "🔍 Token analysis:"
    echo "Token length: ${#ACCESS_TOKEN}"
    echo "Token starts with: ${ACCESS_TOKEN:0:20}..."
    echo "Token ends with: ...${ACCESS_TOKEN: -20}"
    
    # Check for problematic characters
    if echo "$ACCESS_TOKEN" | grep -q '[[:space:]]'; then
      echo "⚠️  Token contains whitespace characters"
    fi
    
    if echo "$ACCESS_TOKEN" | grep -q '[^A-Za-z0-9._-]'; then
      echo "⚠️  Token contains non-standard characters"
    fi
  fi
fi

echo ""
echo "🔚 Test completed"
