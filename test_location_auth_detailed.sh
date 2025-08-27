#!/bin/bash

echo "🔍 DETAILED LOCATION SETTINGS AUTHORIZATION TEST"
echo "================================================"

# Configuration
API_BASE_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
BUSINESS_ID="business_1756220656049_ee98qktepks"
USERNAME="g87_a@yahoo.com"
PASSWORD="Gha@551987"

echo ""
echo "🔐 Step 1: Authentication with Cognito..."

# Get access token using Cognito directly
AUTH_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/x-amz-json-1.1" \
  -H "X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth" \
  -d '{
    "AuthFlow": "USER_PASSWORD_AUTH",
    "ClientId": "1tl9g7nk2k2chtj5fg960fgdth",
    "AuthParameters": {
      "USERNAME": "'$USERNAME'",
      "PASSWORD": "'$PASSWORD'"
    }
  }' \
  "https://cognito-idp.us-east-1.amazonaws.com/")

ACCESS_TOKEN=$(echo $AUTH_RESPONSE | jq -r '.AuthenticationResult.AccessToken // empty')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo "❌ Authentication failed"
  echo "Response: $AUTH_RESPONSE"
  exit 1
fi

echo "✅ Authentication successful"
echo "🎫 Token length: ${#ACCESS_TOKEN}"

echo ""
echo "🧪 Step 2: Testing Working Hours (Known Working)..."

WORKING_HOURS_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "$API_BASE_URL/businesses/$BUSINESS_ID/working-hours")

WH_HTTP_STATUS=$(echo $WORKING_HOURS_RESPONSE | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')
WH_BODY=$(echo $WORKING_HOURS_RESPONSE | sed -E 's/HTTP_STATUS:[0-9]{3}$//')

echo "Working Hours - Status: $WH_HTTP_STATUS"
if [ "$WH_HTTP_STATUS" = "200" ]; then
  echo "✅ Working hours endpoint: AUTHORIZED"
else
  echo "❌ Working hours endpoint: FAILED"
  echo "Response: $WH_BODY"
fi

echo ""
echo "🎯 Step 3: Testing Location Settings (Problem Endpoint)..."

LOCATION_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "$API_BASE_URL/businesses/$BUSINESS_ID/location-settings")

LOC_HTTP_STATUS=$(echo $LOCATION_RESPONSE | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')
LOC_BODY=$(echo $LOCATION_RESPONSE | sed -E 's/HTTP_STATUS:[0-9]{3}$//')

echo "Location Settings - Status: $LOC_HTTP_STATUS"
if [ "$LOC_HTTP_STATUS" = "200" ]; then
  echo "✅ Location settings endpoint: AUTHORIZED"
else
  echo "❌ Location settings endpoint: FAILED"
  echo "Response: $LOC_BODY"
fi

echo ""
echo "📊 ANALYSIS:"
echo "============"

if [ "$WH_HTTP_STATUS" = "200" ] && [ "$LOC_HTTP_STATUS" != "200" ]; then
  echo "🔍 Same token works for working-hours but not location-settings"
  echo "🔍 This suggests an endpoint-specific issue, not token corruption"
  echo ""
  echo "Possible causes:"
  echo "1. Different Lambda functions deployed with different code"
  echo "2. API Gateway routing issue"
  echo "3. Different authorization configuration"
  echo "4. Location settings endpoint deployment problem"
elif [ "$WH_HTTP_STATUS" != "200" ] && [ "$LOC_HTTP_STATUS" != "200" ]; then
  echo "🔍 Both endpoints failing - token or general authorization issue"
elif [ "$WH_HTTP_STATUS" = "200" ] && [ "$LOC_HTTP_STATUS" = "200" ]; then
  echo "✅ Both endpoints working - authorization is correct!"
else
  echo "🔍 Mixed results - needs further investigation"
fi
