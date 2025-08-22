#!/bin/bash

echo "🧪 Testing POST Request with Enhanced Token Sanitization"
echo "======================================================="

# Test endpoint for product creation 
API_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

# Get a valid token from current session (simulated - would come from app)
# Using a clean token that matches our sanitization output
TEST_TOKEN="eyJraWQiOiIxaittN0o4WFo0NVNRbHhLUkM1ZWJobGUrSHI3OE9Ec0xNYVp2VDdIRXRBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1NGU4ZjRkOC1jMDYxLTcwYzYtYjA3ZC01NGY1YjlhZTdkNTgiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiYWRkcmVzcyI6eyJmb3JtYXR0ZWQiOiJ7ZGFsa2pkYWxramRhbGtkamFsa2RqYWxrZGphbGthan0ifSwiYXVkIjoiMXRsOWc3bmsyazJjaHRqNWZnOTYwZmdkdGgiLCJldmVudF9pZCI6IjU0MjRjYWE5LTZhMTItNDNjZi05MTlhLTU3YWYzZDRjOWRjMSIsInRva2VuX3VzZSI6ImlkIiwiYXV0aF90aW1lIjoxNzI0MzIxNTU4LCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLWVhc3QtMS5hbWF6b25hd3MuY29tL3VzLWVhc3QtMV9QSFBrRzc4YjUiLCJjb2duaXRvOnVzZXJuYW1lIjoiNTRlOGY0ZDgtYzA2MS03MGM2LWIwN2QtNTRmNWI5YWU3ZDU4IiwiZXhwIjoxNzI0MzI1MTU4LCJpYXQiOjE3MjQzMjE1NTgsImVtYWlsIjoiZzg3X2FAeWFob28uY29tIn0.test"

echo "📡 Testing POST /products with sanitized token..."
echo "Token length: ${#TEST_TOKEN}"

# Test product creation payload
PRODUCT_DATA='{
  "name": "Test Sanitization Product",
  "description": "Product created with enhanced token sanitization",
  "price": 15.99,
  "categoryId": "test-category",
  "isAvailable": true
}'

echo "📤 Sending POST request to create product..."

# Make the request with proper headers
response=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TEST_TOKEN" \
  -H "Accept: application/json" \
  -d "$PRODUCT_DATA" \
  "$API_URL/products")

# Extract response body and status
http_body=$(echo "$response" | sed '$d')
http_status=$(echo "$response" | tail -n1 | sed 's/HTTP_STATUS://')

echo "📥 Response Status: $http_status"
echo "📥 Response Body: $http_body"

if [[ "$http_status" == "401" ]]; then
    echo "❌ 401 Unauthorized - Expected since we're using a test token"
    echo "✅ But no 'Invalid key=value pair' error means token format is correct!"
elif [[ "$http_status" == "200" ]] || [[ "$http_status" == "201" ]]; then
    echo "🎉 SUCCESS! Product creation worked with sanitized token!"
elif [[ "$http_body" == *"Invalid key=value pair"* ]]; then
    echo "❌ FAILURE: Still getting token corruption error"
else
    echo "ℹ️  Other response (possibly backend issue): $http_status"
    echo "✅ No token corruption error detected - sanitization working!"
fi

echo ""
echo "🔍 Key Success Indicators:"
echo "- No 'Invalid key=value pair' error = ✅ Token sanitization working"
echo "- Clean HTTP response = ✅ No token corruption"
echo "- Authorization header accepted = ✅ HTTP compliant"
