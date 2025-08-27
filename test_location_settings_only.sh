#!/bin/bash

echo "🧪 Testing Location Settings Endpoint Specifically"
echo "================================================="

API_BASE="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
BUSINESS_ID="business_1756220656049_ee98qktepks"

# Step 1: Get a fresh auth token
echo "🔐 Step 1: Getting fresh authentication token..."
AUTH_RESPONSE=$(curl -s -X POST "$API_BASE/auth/signin" \
  -H "Content-Type: application/json" \
  -d '{"email": "g87_a@yahoo.com", "password": "Gha@551987"}')

echo "Auth Response: $AUTH_RESPONSE"

ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.data.AccessToken // empty')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo "❌ Authentication failed"
  exit 1
fi

echo "✅ Authentication successful"
echo "Token length: ${#ACCESS_TOKEN}"

# Step 2: Test PUT location-settings (this is where the user gets unauthorized)
echo ""
echo "📍 Step 2: Testing PUT /businesses/$BUSINESS_ID/location-settings..."

PUT_DATA='{
  "city": "Baghdad",
  "district": "Karrada", 
  "street": "Test Street 123",
  "country": "Iraq",
  "latitude": 33.3152,
  "longitude": 44.3661,
  "address": "Test Street 123, Karrada, Baghdad, Iraq"
}'

echo "Request data: $PUT_DATA"

PUT_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  -X PUT \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PUT_DATA" \
  "$API_BASE/businesses/$BUSINESS_ID/location-settings")

HTTP_STATUS=$(echo $PUT_RESPONSE | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')
RESPONSE_BODY=$(echo $PUT_RESPONSE | sed -E 's/HTTP_STATUS:[0-9]{3}$//')

echo "📊 HTTP Status: $HTTP_STATUS"
echo "📋 Response Body: $RESPONSE_BODY"

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ Location settings update successful!"
elif [ "$HTTP_STATUS" = "401" ]; then
  echo "❌ 401 Unauthorized - This is the issue!"
  echo "🔍 Checking what's in the response..."
  echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "Raw response: $RESPONSE_BODY"
elif [ "$HTTP_STATUS" = "403" ]; then
  echo "❌ 403 Forbidden - Access denied to business"
else
  echo "❌ Unexpected status: $HTTP_STATUS"
  echo "Response: $RESPONSE_BODY"
fi

echo ""
echo "🎯 Summary:"
echo "==========="
echo "• Working hours endpoint: ✅ Working (from CloudWatch logs)"
echo "• Location settings endpoint: Status $HTTP_STATUS"

if [ "$HTTP_STATUS" != "200" ]; then
  echo ""
  echo "🔍 Next steps:"
  echo "1. Check CloudWatch logs for this specific request"
  echo "2. Compare with working-hours endpoint that works"
  echo "3. Look for differences in authorization logic"
fi
