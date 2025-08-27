#!/bin/bash

echo "🧪 Quick Location Settings Test"
echo "================================"

# Get token
echo "🔐 Getting access token..."
AUTH_RESPONSE=$(curl -s -X POST "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/signin" \
  -H "Content-Type: application/json" \
  -d '{"email": "g87_a@yahoo.com", "password": "Gha@551987"}')

ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.data.AccessToken')
ID_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.data.IdToken')
BUSINESS_ID="business_1756220656049_ee98qktepks"

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Failed to get access token"
  echo "Response: $AUTH_RESPONSE"
  exit 1
fi

echo "✅ Access token obtained (length: ${#ACCESS_TOKEN})"
echo "✅ ID token obtained (length: ${#ID_TOKEN})"

# Use ID token for API Gateway (our fix!)
TOKEN="$ID_TOKEN"
echo "🎫 Using ID token for testing (contains required 'aud' field)"

# Test GET location settings
echo ""
echo "📍 Testing GET location settings..."
GET_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X GET "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/businesses/$BUSINESS_ID/location-settings" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

HTTP_STATUS=$(echo "$GET_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$GET_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')

echo "Status: $HTTP_STATUS"
echo "Response: $RESPONSE_BODY"

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ GET location settings: SUCCESS"
elif [ "$HTTP_STATUS" = "401" ]; then
  echo "❌ Still getting 401 Unauthorized"
else
  echo "ℹ️ HTTP Status: $HTTP_STATUS"
fi

# Test PUT location settings
echo ""
echo "📍 Testing PUT location settings..."
PUT_DATA='{"latitude": 33.3152, "longitude": 44.3661, "city": "Baghdad", "district": "Karrada", "street": "Abu Nuwas Street", "country": "Iraq"}'

PUT_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X PUT "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/businesses/$BUSINESS_ID/location-settings" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PUT_DATA")

HTTP_STATUS=$(echo "$PUT_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$PUT_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')

echo "Status: $HTTP_STATUS"
echo "Response: $RESPONSE_BODY"

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ PUT location settings: SUCCESS"
  echo "🎉 Authorization issue FIXED!"
elif [ "$HTTP_STATUS" = "401" ]; then
  echo "❌ Still getting 401 Unauthorized"
else
  echo "ℹ️ HTTP Status: $HTTP_STATUS"
fi
