#!/bin/bash

echo "🧪 TESTING LOCATION SETTINGS ENDPOINTS"
echo "======================================"

# Configuration
API_BASE_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
BUSINESS_ID="business_1756220656049_ee98qktepks"

# Test credentials (using confirmed user from Cognito)
USERNAME="g87_a@yahoo.com"
PASSWORD="Gha@551987"

echo ""
echo "🔐 Step 1: Authentication..."

# Get access token
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

echo ""
echo "📍 Step 2: Testing GET Location Settings..."

# Test GET location settings
GET_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "$API_BASE_URL/businesses/$BUSINESS_ID/location-settings")

GET_HTTP_STATUS=$(echo $GET_RESPONSE | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')
GET_BODY=$(echo $GET_RESPONSE | sed -E 's/HTTP_STATUS:[0-9]{3}$//')

echo "Status Code: $GET_HTTP_STATUS"
echo "Response Body: $GET_BODY"

if [ "$GET_HTTP_STATUS" = "200" ]; then
  echo "✅ GET location settings successful"
else
  echo "❌ GET location settings failed"
fi

echo ""
echo "💾 Step 3: Testing PUT Location Settings..."

# Test PUT location settings
PUT_DATA='{
  "latitude": 25.2854,
  "longitude": 51.5310,
  "city": "Test City",
  "district": "Test District", 
  "street": "Test Street",
  "country": "Qatar",
  "address": "Test Street, Test District, Test City, Qatar"
}'

PUT_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  -X PUT \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PUT_DATA" \
  "$API_BASE_URL/businesses/$BUSINESS_ID/location-settings")

PUT_HTTP_STATUS=$(echo $PUT_RESPONSE | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')
PUT_BODY=$(echo $PUT_RESPONSE | sed -E 's/HTTP_STATUS:[0-9]{3}$//')

echo "Status Code: $PUT_HTTP_STATUS"
echo "Response Body: $PUT_BODY"

if [ "$PUT_HTTP_STATUS" = "200" ]; then
  echo "✅ PUT location settings successful"
else
  echo "❌ PUT location settings failed"
fi

echo ""
echo "🔍 Step 4: Verifying Data Persistence..."

# Test GET again to verify data was saved
VERIFY_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "$API_BASE_URL/businesses/$BUSINESS_ID/location-settings")

VERIFY_HTTP_STATUS=$(echo $VERIFY_RESPONSE | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')
VERIFY_BODY=$(echo $VERIFY_RESPONSE | sed -E 's/HTTP_STATUS:[0-9]{3}$//')

echo "Status Code: $VERIFY_HTTP_STATUS"
echo "Response Body: $VERIFY_BODY"

if [ "$VERIFY_HTTP_STATUS" = "200" ]; then
  echo "✅ Data persistence verification successful"
  
  # Check if specific fields are present
  if echo "$VERIFY_BODY" | jq -e '.city' > /dev/null 2>&1; then
    CITY=$(echo "$VERIFY_BODY" | jq -r '.city')
    DISTRICT=$(echo "$VERIFY_BODY" | jq -r '.district')
    STREET=$(echo "$VERIFY_BODY" | jq -r '.street')
    
    echo "📋 Retrieved location data:"
    echo "   City: $CITY"
    echo "   District: $DISTRICT"
    echo "   Street: $STREET"
    
    if [ "$CITY" = "Test City" ] && [ "$DISTRICT" = "Test District" ] && [ "$STREET" = "Test Street" ]; then
      echo "✅ Location data mapping is working correctly!"
    else
      echo "⚠️ Location data mapping may have issues"
    fi
  else
    echo "⚠️ Response format may not include expected fields"
  fi
else
  echo "❌ Data persistence verification failed"
fi

echo ""
echo "📊 FINAL RESULTS:"
echo "=================="
echo "Authentication: $([ -n "$ACCESS_TOKEN" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "GET Location Settings: $([ "$GET_HTTP_STATUS" = "200" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "PUT Location Settings: $([ "$PUT_HTTP_STATUS" = "200" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "Data Persistence: $([ "$VERIFY_HTTP_STATUS" = "200" ] && echo "✅ PASS" || echo "❌ FAIL")"

echo ""
if [ "$GET_HTTP_STATUS" = "200" ] && [ "$PUT_HTTP_STATUS" = "200" ] && [ "$VERIFY_HTTP_STATUS" = "200" ]; then
  echo "🎉 LOCATION SETTINGS BACKEND: FULLY WORKING!"
else
  echo "⚠️ Some issues detected - see details above"
fi
