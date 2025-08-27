#!/bin/bash

echo "🧪 Testing Both Access and ID Tokens for Location Settings"
echo "=========================================================="

# Get tokens
echo "🔐 Getting tokens from signin..."
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

echo ""
echo "🔍 Testing with ACCESS TOKEN:"
echo "=============================="

GET_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X GET "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/businesses/$BUSINESS_ID/location-settings" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json")

HTTP_STATUS=$(echo "$GET_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$GET_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')

echo "Access Token - Status: $HTTP_STATUS"
echo "Access Token - Response: $RESPONSE_BODY"

echo ""
echo "🔍 Testing with ID TOKEN:"
echo "=========================="

GET_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X GET "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/businesses/$BUSINESS_ID/location-settings" \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json")

HTTP_STATUS=$(echo "$GET_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$GET_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')

echo "ID Token - Status: $HTTP_STATUS"
echo "ID Token - Response: $RESPONSE_BODY"

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ ID TOKEN WORKS! Authorization fix confirmed"
else
  echo "❌ ID token also fails with status: $HTTP_STATUS"
fi

echo ""
echo "🔍 Testing Working Hours with ID TOKEN:"
echo "======================================="

GET_WH_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X GET "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/businesses/$BUSINESS_ID/working-hours" \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json")

HTTP_STATUS=$(echo "$GET_WH_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$GET_WH_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')

echo "Working Hours - Status: $HTTP_STATUS"
echo "Working Hours - Response: $RESPONSE_BODY"

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ Working Hours endpoint is working!"
else
  echo "❌ Working Hours endpoint fails with status: $HTTP_STATUS"
fi
