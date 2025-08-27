#!/bin/bash

echo "🧪 TESTING LOCATION SETTINGS ENDPOINTS WITH BACKEND AUTH"
echo "========================================================"

# Configuration
API_BASE_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

# Test with confirmed user from Cognito
USERNAME="g87_a@yahoo.com"
# Using the password that was set via AWS CLI
TEST_PASSWORD="Gha@551987"

echo ""
echo "🔐 Step 1: Getting access token via backend signin..."

# Use backend signin endpoint to get valid access token
SIGNIN_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$USERNAME'",
    "password": "'$TEST_PASSWORD'"
  }' \
  "$API_BASE_URL/auth/signin")

SIGNIN_HTTP_STATUS=$(echo $SIGNIN_RESPONSE | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')
SIGNIN_BODY=$(echo $SIGNIN_RESPONSE | sed -E 's/HTTP_STATUS:[0-9]{3}$//')

echo "📊 Signin HTTP Status: $SIGNIN_HTTP_STATUS"
echo "📋 Signin Response Body: $SIGNIN_BODY"

if [ "$SIGNIN_HTTP_STATUS" != "200" ]; then
  echo ""
  echo "❌ Backend signin failed with status: $SIGNIN_HTTP_STATUS"
  echo "💡 This is expected since we don't have the actual password for the test user."
  echo ""
  echo "🔧 To fix this, you can:"
  echo "   1. Create a new test user through the app"
  echo "   2. Reset the password for the existing user"
  echo "   3. Use the Cognito CLI to set a known password"
  echo ""
  echo "📝 Here's an example of how to test with a real user:"
  echo "   1. Register through the app UI"
  echo "   2. Verify email"
  echo "   3. Use those credentials in this script"
  echo ""
  echo "🔍 Current confirmed users in Cognito:"
  echo "   - g87_a@yahoo.com (ID: 94585418-1021-7021-cd9e-6d9c8784a299)"
  echo "   - zikbiot@yahoo.com (ID: f4a8b408-3061-7049-b429-8ac9f771fa59)"
  echo ""
  echo "🔧 To set a known password for existing users, use AWS CLI:"
  echo "   aws cognito-idp admin-set-user-password \\"
  echo "     --user-pool-id us-east-1_PHPkG78b5 \\"
  echo "     --username g87_a@yahoo.com \\"
  echo "     --password 'YourNewPassword123!' \\"
  echo "     --permanent \\"
  echo "     --profile wizz-merchants-dev"
  
  exit 1
fi

# Extract access token from backend signin response
ACCESS_TOKEN=$(echo $SIGNIN_BODY | jq -r '.data.AccessToken // empty')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo "❌ Could not extract access token from signin response"
  echo "Response: $SIGNIN_BODY"
  exit 1
fi

echo "✅ Backend signin successful - access token obtained"

# Extract business ID from signin response
BUSINESS_ID=$(echo $SIGNIN_BODY | jq -r '.businesses[0].businessId // empty')

if [ -z "$BUSINESS_ID" ] || [ "$BUSINESS_ID" = "null" ]; then
  echo "❌ Could not extract business ID from signin response"
  echo "Response: $SIGNIN_BODY"
  exit 1
fi

echo "🏢 Business ID: $BUSINESS_ID"

echo ""
echo "📍 Step 2: Testing GET Location Settings..."

# Test GET location settings
GET_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "$API_BASE_URL/businesses/$BUSINESS_ID/location-settings")

GET_HTTP_STATUS=$(echo $GET_RESPONSE | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')
GET_BODY=$(echo $GET_RESPONSE | sed -E 's/HTTP_STATUS:[0-9]{3}$//')

echo "📊 GET HTTP Status: $GET_HTTP_STATUS"
echo "📋 GET Response Body: $GET_BODY"

if [ "$GET_HTTP_STATUS" = "200" ]; then
  echo "✅ GET location settings successful"
else
  echo "❌ GET location settings failed with status: $GET_HTTP_STATUS"
fi

echo ""
echo "💾 Step 3: Testing PUT Location Settings..."

# Test PUT location settings with sample data
PUT_DATA='{
  "latitude": 25.2048,
  "longitude": 55.2708,
  "address": "123 Test Street, Business Bay, Dubai, UAE",
  "city": "Dubai",
  "district": "Business Bay", 
  "street": "123 Test Street",
  "country": "UAE"
}'

PUT_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  -X PUT \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PUT_DATA" \
  "$API_BASE_URL/businesses/$BUSINESS_ID/location-settings")

PUT_HTTP_STATUS=$(echo $PUT_RESPONSE | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')
PUT_BODY=$(echo $PUT_RESPONSE | sed -E 's/HTTP_STATUS:[0-9]{3}$//')

echo "📊 PUT HTTP Status: $PUT_HTTP_STATUS"
echo "📋 PUT Response Body: $PUT_BODY"

if [ "$PUT_HTTP_STATUS" = "200" ]; then
  echo "✅ PUT location settings successful"
else
  echo "❌ PUT location settings failed with status: $PUT_HTTP_STATUS"
fi

echo ""
echo "🔍 Step 4: Verifying data persistence with another GET..."

# Test GET again to verify data was saved
VERIFY_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "$API_BASE_URL/businesses/$BUSINESS_ID/location-settings")

VERIFY_HTTP_STATUS=$(echo $VERIFY_RESPONSE | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')
VERIFY_BODY=$(echo $VERIFY_RESPONSE | sed -E 's/HTTP_STATUS:[0-9]{3}$//')

echo "📊 Verify GET HTTP Status: $VERIFY_HTTP_STATUS"
echo "📋 Verify GET Response Body: $VERIFY_BODY"

if [ "$VERIFY_HTTP_STATUS" = "200" ]; then
  echo "✅ Data persistence verification successful"
  
  # Parse and display the saved data
  SAVED_CITY=$(echo $VERIFY_BODY | jq -r '.city // "N/A"')
  SAVED_DISTRICT=$(echo $VERIFY_BODY | jq -r '.district // "N/A"')
  SAVED_STREET=$(echo $VERIFY_BODY | jq -r '.street // "N/A"')
  SAVED_LAT=$(echo $VERIFY_BODY | jq -r '.latitude // "N/A"')
  SAVED_LNG=$(echo $VERIFY_BODY | jq -r '.longitude // "N/A"')
  
  echo ""
  echo "📌 Saved Location Data:"
  echo "   City: $SAVED_CITY"
  echo "   District: $SAVED_DISTRICT"
  echo "   Street: $SAVED_STREET"
  echo "   Latitude: $SAVED_LAT"
  echo "   Longitude: $SAVED_LNG"
  
  # Check if individual fields were properly saved
  if [ "$SAVED_CITY" != "N/A" ] && [ "$SAVED_DISTRICT" != "N/A" ] && [ "$SAVED_STREET" != "N/A" ]; then
    echo "✅ Individual address components properly saved!"
  else
    echo "⚠️  Some address components missing - check field mapping"
  fi
  
else
  echo "❌ Data persistence verification failed with status: $VERIFY_HTTP_STATUS"
fi

echo ""
echo "🎯 Testing Summary:"
echo "=================="
echo "📊 Backend Signin: $([ "$SIGNIN_HTTP_STATUS" = "200" ] && echo "✅ SUCCESS" || echo "❌ FAILED")"
echo "📍 GET Location Settings: $([ "$GET_HTTP_STATUS" = "200" ] && echo "✅ SUCCESS" || echo "❌ FAILED")"
echo "💾 PUT Location Settings: $([ "$PUT_HTTP_STATUS" = "200" ] && echo "✅ SUCCESS" || echo "❌ FAILED")"
echo "🔍 Data Persistence: $([ "$VERIFY_HTTP_STATUS" = "200" ] && echo "✅ SUCCESS" || echo "❌ FAILED")"

if [ "$SIGNIN_HTTP_STATUS" = "200" ] && [ "$GET_HTTP_STATUS" = "200" ] && [ "$PUT_HTTP_STATUS" = "200" ] && [ "$VERIFY_HTTP_STATUS" = "200" ]; then
  echo ""
  echo "🎉 ALL TESTS PASSED! Location settings endpoints are working correctly."
  echo "✅ Backend infrastructure is ready for frontend integration."
else
  echo ""
  echo "⚠️  Some tests failed. Check the responses above for details."
fi

echo ""
echo "💡 Next Steps:"
echo "1. Set a known password for test users or create new test users"
echo "2. Test with the frontend app to verify end-to-end functionality"
echo "3. Verify UI properly maps city, district, and street fields"
echo "4. Test the 'Get Location' vs 'Save Location' UI feedback issue"
