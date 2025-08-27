#!/bin/bash

echo "🧪 Testing Location Settings Update Only"
echo "========================================"

# Get fresh token
echo "🔐 Getting fresh authentication token..."
AUTH_RESPONSE=$(curl -s -X POST "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/signin" \
  -H "Content-Type: application/json" \
  -d '{"email": "g87_a@yahoo.com", "password": "Gha@551987"}')

ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.data.AccessToken // empty')
BUSINESS_ID="business_1756220656049_ee98qktepks"

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo "❌ Authentication failed"
  echo "$AUTH_RESPONSE"
  exit 1
fi

echo "✅ Got fresh token (length: ${#ACCESS_TOKEN})"

# Test location settings update
echo ""
echo "📍 Testing Location Settings Update..."
LOCATION_DATA='{
  "latitude": 32.0617,
  "longitude": 44.2387,
  "address": "Test Street 123, Karrada, Baghdad, Iraq",
  "city": "Baghdad",
  "district": "Karrada", 
  "street": "Test Street 123",
  "country": "Iraq"
}'

PUT_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X PUT \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$LOCATION_DATA" \
  "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/businesses/$BUSINESS_ID/location-settings")

HTTP_STATUS=$(echo "$PUT_RESPONSE" | tail -n1 | cut -d: -f2)
RESPONSE_BODY=$(echo "$PUT_RESPONSE" | head -n -1)

echo "📊 HTTP Status: $HTTP_STATUS"
echo "📋 Response: $RESPONSE_BODY"

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ Location settings update successful!"
elif [ "$HTTP_STATUS" = "401" ]; then
  echo "❌ Still getting 401 Unauthorized - checking CloudWatch logs..."
else
  echo "⚠️ Unexpected status: $HTTP_STATUS"
fi
