#!/bin/bash

echo "🔍 Testing Product Handler Internal Authorization"
echo "==============================================="

API_BASE="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
EMAIL="G87_a@yahoo.com"
PASSWORD="Password123!"

echo "📧 Getting access token for: $EMAIL"

# Get access token
SIGNIN_RESPONSE=$(curl -s -X POST \
  "$API_BASE/auth/signin" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'"$EMAIL"'",
    "password": "'"$PASSWORD"'"
  }')

ACCESS_TOKEN=$(echo "$SIGNIN_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['data']['AccessToken'])" 2>/dev/null)

if [ -n "$ACCESS_TOKEN" ]; then
    echo "✅ Access Token obtained"
    
    echo ""
    echo "🛍️ Testing product endpoint with token..."
    
    # Test with detailed curl output
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\nRESPONSE_TIME:%{time_total}\n" \
      -X GET "$API_BASE/products" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ACCESS_TOKEN")
    
    echo "Response:"
    echo "$RESPONSE"
    
    # Extract just the JSON part
    JSON_RESPONSE=$(echo "$RESPONSE" | head -n -2)
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
    
    echo ""
    echo "HTTP Status Code: $HTTP_CODE"
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ SUCCESS: Product endpoint is working!"
        # Count products
        PRODUCT_COUNT=$(echo "$JSON_RESPONSE" | grep -o '"productId"' | wc -l | tr -d ' ')
        echo "📦 Products found: $PRODUCT_COUNT"
    else
        echo "❌ Failed with HTTP $HTTP_CODE"
        echo "Response body: $JSON_RESPONSE"
    fi
else
    echo "❌ Failed to get access token"
fi
