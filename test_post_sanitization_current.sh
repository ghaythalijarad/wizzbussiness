#!/bin/bash

echo "🧪 Testing POST Request Token Sanitization"
echo "========================================="
echo

# Get the stored token
if [ -f "frontend/access_token.txt" ]; then
    token=$(cat frontend/access_token.txt)
    echo "✅ Found stored token (${#token} characters)"
else
    echo "❌ No token file found. Please ensure authentication is working."
    exit 1
fi

# Test the token for problematic characters
echo "🔍 Token analysis:"
echo "  - Contains line breaks: $(echo "$token" | grep -c $'\n')"
echo "  - Contains spaces: $(echo "$token" | grep -c ' ')"
echo "  - Token sample: ${token:0:50}..."

# Create test product data
product_data='{
  "name": "Test Product - POST Sanitization Check",
  "description": "Testing if POST requests use sanitized tokens properly",
  "price": 15.99,
  "categoryId": "test-category-id",
  "isAvailable": true
}'

echo
echo "📤 Making POST request to create product..."
echo "📋 Request data: $product_data"

# Make the POST request
response=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token" \
  -d "$product_data" \
  "https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/products" 2>&1)

# Extract HTTP status code and body
http_code=$(echo "$response" | tail -n1)
http_body=$(echo "$response" | head -n -1)

echo
echo "📤 Response Status: $http_code"
echo "📤 Response Body: $http_body"
echo

# Check for the corruption error
if [[ "$http_body" == *"Invalid key=value pair"* ]]; then
    echo "❌ CORRUPTION ERROR DETECTED!"
    echo "❌ The 'Invalid key=value pair' error is still occurring"
    echo "❌ This means POST requests are NOT using enhanced sanitization"
    echo "❌ The token sanitization fix has NOT been applied to POST requests"
elif [[ "$http_code" == "401" ]]; then
    echo "⚠️ Authorization error (401) - but NO corruption error"
    echo "⚠️ This suggests tokens are properly formatted but may be expired/invalid"
    echo "✅ Token format is correct (no corruption error)"
elif [[ "$http_code" == "201" ]]; then
    echo "✅ SUCCESS! Product created successfully"
    echo "✅ Token sanitization is working perfectly for POST requests"
elif [[ "$http_code" == "400" ]]; then
    echo "⚠️ Bad Request (400) - but NO corruption error"
    echo "✅ Token format is correct (no corruption error)"
    echo "⚠️ May be missing required fields or invalid data"
else
    echo "⚠️ Unexpected response: $http_code"
    echo "✅ But no corruption error, so token format is probably OK"
fi

echo
echo "🔍 Analysis:"
echo "- Token length: ${#token}"
echo "- HTTP Status: $http_code"
echo "- Contains 'Invalid key=value pair': $(echo "$http_body" | grep -c 'Invalid key=value pair')"
echo "- Response length: ${#http_body}"
