#!/bin/bash

echo "🔧 COMPREHENSIVE COGNITO AUTHORIZER DIAGNOSTIC"
echo "=============================================="
echo ""

# Test credentials
EMAIL="g87_a@yahoo.com"
PASSWORD="Gha@551987"
API_BASE="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

echo "📋 Test Configuration:"
echo "User Pool ID: us-east-1_PHPkG78b5"
echo "Client ID: 1tl9g7nk2k2chtj5fg960fgdth"
echo "Account ID: 031857856164"
echo "Expected ARN: arn:aws:cognito-idp:us-east-1:031857856164:userpool/us-east-1_PHPkG78b5"
echo ""

echo "1️⃣ Authentication Test..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/signin" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}")

if echo "$LOGIN_RESPONSE" | grep -q '"success":true'; then
  echo "✅ Authentication successful"
else
  echo "❌ Authentication failed"
  echo "Response: $LOGIN_RESPONSE"
  exit 1
fi

ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.AccessToken')
BUSINESS_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.businesses[0].businessId')

echo "Business ID: $BUSINESS_ID"
echo "Token length: ${#ACCESS_TOKEN}"
echo ""

echo "2️⃣ JWT Token Analysis..."
echo "Token preview: ${ACCESS_TOKEN:0:50}..."

# Decode payload
PAYLOAD=$(echo "$ACCESS_TOKEN" | cut -d'.' -f2)
# Add padding if needed
case ${#PAYLOAD} in
  *0) PAYLOAD="$PAYLOAD" ;;
  *1) PAYLOAD="$PAYLOAD===" ;;
  *2) PAYLOAD="$PAYLOAD==" ;;
  *3) PAYLOAD="$PAYLOAD=" ;;
esac

echo "Decoding JWT payload..."
DECODED_PAYLOAD=$(echo "$PAYLOAD" | base64 -d 2>/dev/null | jq .)
echo "$DECODED_PAYLOAD"
echo ""

echo "3️⃣ Testing Protected Endpoints..."

# Test location settings
echo "Testing location settings endpoint..."
LOCATION_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X GET "$API_BASE/businesses/$BUSINESS_ID/location-settings" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$LOCATION_RESPONSE" | grep -o 'HTTP_CODE:[0-9]*' | cut -d: -f2)
RESPONSE_BODY=$(echo "$LOCATION_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

echo "Location settings HTTP code: $HTTP_CODE"
echo "Location settings response: $RESPONSE_BODY"

if [ "$HTTP_CODE" = "401" ]; then
  echo "❌ Still getting 401 Unauthorized"
elif [ "$HTTP_CODE" = "200" ]; then
  echo "✅ Location settings working!"
else
  echo "⚠️ Unexpected HTTP code: $HTTP_CODE"
fi
echo ""

# Test user businesses endpoint
echo "Testing user businesses endpoint..."
USER_BIZ_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X GET "$API_BASE/auth/user-businesses" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$USER_BIZ_RESPONSE" | grep -o 'HTTP_CODE:[0-9]*' | cut -d: -f2)
RESPONSE_BODY=$(echo "$USER_BIZ_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

echo "User businesses HTTP code: $HTTP_CODE"
echo "User businesses response: $RESPONSE_BODY"
echo ""

# Test business profile endpoint
echo "Testing business profile endpoint..."
PROFILE_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X GET "$API_BASE/businesses/$BUSINESS_ID/profile" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$PROFILE_RESPONSE" | grep -o 'HTTP_CODE:[0-9]*' | cut -d: -f2)
RESPONSE_BODY=$(echo "$PROFILE_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

echo "Business profile HTTP code: $HTTP_CODE"
echo "Business profile response: $RESPONSE_BODY"
echo ""

echo "4️⃣ Diagnosis Summary..."
if echo "$LOCATION_RESPONSE$USER_BIZ_RESPONSE$PROFILE_RESPONSE" | grep -q "HTTP_CODE:401"; then
  echo "❌ COGNITO AUTHORIZER STILL FAILING"
  echo ""
  echo "Possible causes:"
  echo "1. API Gateway authorizer cache not updated (wait 5-10 minutes)"
  echo "2. Cognito User Pool ARN mismatch in deployed configuration"
  echo "3. Token format or validation issue"
  echo "4. OpenAPI specification syntax error"
  echo ""
  echo "Next steps:"
  echo "- Wait 5-10 minutes for API Gateway cache to update"
  echo "- Check CloudFormation template deployment logs"
  echo "- Verify the actual deployed API Gateway authorizer configuration"
else
  echo "✅ COGNITO AUTHORIZER WORKING!"
  echo "🎉 Location settings endpoints should be functional"
fi
