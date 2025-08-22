#!/bin/bash

echo "🧪 Testing POST vs GET Request Token Sanitization"
echo "================================================="
echo

# Check if we have a valid token from previous sessions
if [ -f "backend/access_token.txt" ]; then
    token=$(cat backend/access_token.txt)
    echo "✅ Found backend token file (${#token} characters)"
elif [ -f "frontend/access_token.txt" ]; then
    token=$(cat frontend/access_token.txt)
    echo "✅ Found frontend token file (${#token} characters)"
else
    echo "❌ No token file found. Creating test with known working token..."
    # Use a sample token format that would trigger the corruption issue
    token="eyJraWQiOiJva3B1RDh5MnA5dkt0OUFBZXZvNkttRXhQXC9Jс2FQRk9MOHhpMGs0WHJJcz0iLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiIzNGY4YjQzOC0xMDcxLTcwOTktMmM3Yy0zZGY4YTM5YjhjMzQiLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAudXMtZWFzdC0xLmFtYXpvbmF3cy5jb21cL3VzLWVhc3QtMV9iRHFuS2RycW8ifQ.corrupted_signature_хwith_cyrillicх"
    echo "⚠️ Using simulated corrupted token for testing"
fi

echo "🔍 Token analysis:"
echo "  - Length: ${#token}"
echo "  - Contains spaces: $(echo "$token" | grep -c ' ')"
echo "  - Contains line breaks: $(echo "$token" | grep -c $'\n')"
echo "  - Contains Cyrillic х: $(echo "$token" | grep -c 'х')"
echo "  - First 50 chars: ${token:0:50}..."

base_url="https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev"

echo
echo "📤 Testing GET /products (should work with sanitization)..."

get_response=$(curl -s -w "\n%{http_code}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token" \
  "$base_url/products" 2>&1)

get_code=$(echo "$get_response" | tail -n1)
get_body=$(echo "$get_response" | head -n -1)

echo "GET Response: $get_code"
if [[ "$get_body" == *"Invalid key=value pair"* ]]; then
    echo "❌ GET request shows corruption error!"
else
    echo "✅ GET request OK (no corruption error)"
fi

echo
echo "📤 Testing POST /products (checking if sanitization works)..."

product_data='{
  "name": "Test Product - Sanitization Check",
  "description": "Testing POST request token sanitization",
  "price": 15.99,
  "categoryId": "test-category-id",
  "isAvailable": true
}'

post_response=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token" \
  -d "$product_data" \
  "$base_url/products" 2>&1)

post_code=$(echo "$post_response" | tail -n1)
post_body=$(echo "$post_response" | head -n -1)

echo "POST Response: $post_code"
if [[ "$post_body" == *"Invalid key=value pair"* ]]; then
    echo "❌ POST request shows corruption error!"
    echo "❌ This means the sanitization is NOT being applied to POST requests"
else
    echo "✅ POST request OK (no corruption error)"
    echo "✅ Token sanitization is working for POST requests"
fi

echo
echo "🔍 COMPARISON:"
echo "GET Request:"
echo "  - Status: $get_code"
echo "  - Has corruption error: $(echo "$get_body" | grep -c 'Invalid key=value pair')"
echo "POST Request:"
echo "  - Status: $post_code"  
echo "  - Has corruption error: $(echo "$post_body" | grep -c 'Invalid key=value pair')"

echo
echo "📋 Analysis:"
if [[ "$get_body" == *"Invalid key=value pair"* ]] && [[ "$post_body" == *"Invalid key=value pair"* ]]; then
    echo "❌ Both GET and POST show corruption - sanitization not working at all"
elif [[ "$get_body" != *"Invalid key=value pair"* ]] && [[ "$post_body" == *"Invalid key=value pair"* ]]; then
    echo "❌ GET works, POST fails - POST requests bypass sanitization"
elif [[ "$get_body" == *"Invalid key=value pair"* ]] && [[ "$post_body" != *"Invalid key=value pair"* ]]; then
    echo "❌ POST works, GET fails - GET requests bypass sanitization (unlikely)"
else
    echo "✅ Both GET and POST work - sanitization is working correctly"
fi
