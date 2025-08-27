#!/bin/bash

echo "🧪 AUTHORIZATION FIX TEST - ID TOKEN PRIORITY"
echo "============================================="

# Get both access and ID tokens
echo "🔐 Getting fresh tokens..."
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

# Test with Access Token (the old way - should fail)
echo ""
echo "🧪 TEST 1: Using ACCESS TOKEN (old way - should fail)"
echo "======================================================"
GET_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X GET "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/businesses/$BUSINESS_ID/location-settings" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json")

HTTP_STATUS=$(echo "$GET_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$GET_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')

echo "Status: $HTTP_STATUS"
echo "Response: $RESPONSE_BODY"

if [ "$HTTP_STATUS" = "401" ]; then
  echo "✅ Expected: Access token correctly rejected (missing aud field)"
else
  echo "❓ Unexpected: Access token worked (Status: $HTTP_STATUS)"
fi

# Test with ID Token (the new way - should work)
echo ""
echo "🎯 TEST 2: Using ID TOKEN (new way - should work)"
echo "================================================="
GET_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X GET "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/businesses/$BUSINESS_ID/location-settings" \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json")

HTTP_STATUS=$(echo "$GET_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$GET_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')

echo "Status: $HTTP_STATUS"
echo "Response: $RESPONSE_BODY"

if [ "$HTTP_STATUS" = "200" ]; then
  echo "🎉 SUCCESS: ID token authorized correctly!"
  echo "✅ Our fix works - the app should now use ID tokens"
elif [ "$HTTP_STATUS" = "401" ]; then
  echo "❌ ID token also rejected - need to investigate further"
else
  echo "ℹ️ Unexpected status: $HTTP_STATUS"
fi

# Test PUT with ID Token
echo ""
echo "🎯 TEST 3: PUT Location Settings with ID TOKEN"
echo "=============================================="
PUT_DATA='{"latitude": 33.3152, "longitude": 44.3661, "city": "Baghdad", "district": "Karrada", "street": "Abu Nuwas Street", "country": "Iraq"}'

PUT_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X PUT "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/businesses/$BUSINESS_ID/location-settings" \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PUT_DATA")

HTTP_STATUS=$(echo "$PUT_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$PUT_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')

echo "Status: $HTTP_STATUS"
echo "Response: $RESPONSE_BODY"

if [ "$HTTP_STATUS" = "200" ]; then
  echo "🎉 SUCCESS: Location settings updated with ID token!"
else
  echo "❌ PUT failed with ID token (Status: $HTTP_STATUS)"
fi

echo ""
echo "📱 FLUTTER APP TESTING"
echo "======================"
echo "Now test in the Flutter app:"
echo "1. Sign out completely"
echo "2. Sign in again (to get fresh ID tokens)" 
echo "3. Go to Location Settings"
echo "4. Try to save location settings"
echo ""
echo "Expected console logs:"
echo "🎫 [TokenManager] Using ID token for authorization"
echo ""
echo "If you see that message, the fix is working!"
