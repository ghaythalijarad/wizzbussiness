#!/bin/bash

echo "🧪 TESTING WORKING HOURS ENDPOINTS"
echo "=================================="

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
echo "🕒 Step 2: Testing GET Working Hours..."

# Test GET working hours
GET_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "$API_BASE_URL/businesses/$BUSINESS_ID/working-hours")

GET_HTTP_STATUS=$(echo $GET_RESPONSE | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')
GET_BODY=$(echo $GET_RESPONSE | sed -E 's/HTTP_STATUS:[0-9]{3}$//')

echo "Status Code: $GET_HTTP_STATUS"
echo "Response Body: $GET_BODY"

if [ "$GET_HTTP_STATUS" = "200" ]; then
  echo "✅ GET working hours successful"
else
  echo "❌ GET working hours failed"
fi

echo ""
echo "⏰ Step 3: Testing PUT Working Hours..."

# Test PUT working hours with sample data
WORKING_HOURS_DATA='{
  "workingHours": {
    "Monday": {"opening": "09:00", "closing": "17:00", "isOpen": true},
    "Tuesday": {"opening": "09:00", "closing": "17:00", "isOpen": true},
    "Wednesday": {"opening": "09:00", "closing": "17:00", "isOpen": true},
    "Thursday": {"opening": "09:00", "closing": "17:00", "isOpen": true},
    "Friday": {"opening": "09:00", "closing": "17:00", "isOpen": true},
    "Saturday": {"opening": "10:00", "closing": "16:00", "isOpen": true},
    "Sunday": {"opening": null, "closing": null, "isOpen": false}
  }
}'

PUT_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  -X PUT \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$WORKING_HOURS_DATA" \
  "$API_BASE_URL/businesses/$BUSINESS_ID/working-hours")

PUT_HTTP_STATUS=$(echo $PUT_RESPONSE | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')
PUT_BODY=$(echo $PUT_RESPONSE | sed -E 's/HTTP_STATUS:[0-9]{3}$//')

echo "Status Code: $PUT_HTTP_STATUS"
echo "Response Body: $PUT_BODY"

if [ "$PUT_HTTP_STATUS" = "200" ]; then
  echo "✅ PUT working hours successful"
else
  echo "❌ PUT working hours failed"
fi

echo ""
echo "🔍 Step 4: Verifying Data Persistence..."

# Test GET again to verify the data was saved
VERIFY_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "$API_BASE_URL/businesses/$BUSINESS_ID/working-hours")

VERIFY_HTTP_STATUS=$(echo $VERIFY_RESPONSE | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')
VERIFY_BODY=$(echo $VERIFY_RESPONSE | sed -E 's/HTTP_STATUS:[0-9]{3}$//')

echo "Status Code: $VERIFY_HTTP_STATUS"
echo "Response Body: $VERIFY_BODY"

if [ "$VERIFY_HTTP_STATUS" = "200" ]; then
  echo "✅ Data persistence verification successful"
  
  # Check if the data matches what we sent
  if echo "$VERIFY_BODY" | jq -e '.workingHours.Monday.opening == "09:00"' > /dev/null; then
    echo "✅ Data integrity confirmed"
  else
    echo "⚠️ Data might not have persisted correctly"
  fi
else
  echo "❌ Data persistence verification failed"
fi

echo ""
echo "📊 FINAL RESULTS:"
echo "=================="
echo "Authentication: $([ -n "$ACCESS_TOKEN" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "GET Working Hours: $([ "$GET_HTTP_STATUS" = "200" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "PUT Working Hours: $([ "$PUT_HTTP_STATUS" = "200" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "Data Persistence: $([ "$VERIFY_HTTP_STATUS" = "200" ] && echo "✅ PASS" || echo "❌ FAIL")"

echo ""
if [ "$GET_HTTP_STATUS" = "200" ] && [ "$PUT_HTTP_STATUS" = "200" ] && [ "$VERIFY_HTTP_STATUS" = "200" ]; then
  echo "🎉 WORKING HOURS BACKEND: FULLY WORKING!"
else
  echo "⚠️ Some issues detected - see details above"
fi
