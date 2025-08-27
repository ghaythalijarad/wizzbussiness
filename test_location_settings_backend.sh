#!/bin/bash

# Backend Location Settings API Test
# Tests location settings save/retrieve functionality with clean tokens

echo "🧪 TESTING LOCATION SETTINGS BACKEND API"
echo "========================================"

# Configuration
API_BASE="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
BUSINESS_ID="business_1756220656049_ee98qktepks"

# Test credentials
EMAIL="g87_a@yahoo.com"
PASSWORD="hadhir1234"

echo "📋 Test Configuration:"
echo "   API Base: $API_BASE"
echo "   Business ID: $BUSINESS_ID"
echo "   Email: $EMAIL"

# Step 1: Authenticate and get clean token
echo ""
echo "🔐 Step 1: Authentication..."
AUTH_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

echo "📤 Auth Response:"
echo "$AUTH_RESPONSE" | jq '.'

# Extract access token
ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.access_token // empty')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo "❌ Authentication failed - no access token received"
  exit 1
fi

echo "✅ Authentication successful"
echo "🔑 Token length: ${#ACCESS_TOKEN}"
echo "🔑 Token preview: ${ACCESS_TOKEN:0:20}...${ACCESS_TOKEN: -10}"

# Check for problematic characters in token
echo ""
echo "🔍 Token Quality Analysis:"
if [[ "$ACCESS_TOKEN" == *"|"* ]]; then
  echo "⚠️  WARNING: Token contains pipe characters"
fi

if [[ "$ACCESS_TOKEN" == "="* ]]; then
  echo "⚠️  WARNING: Token starts with equals sign"
fi

if [[ "$ACCESS_TOKEN" == *$'\n'* ]] || [[ "$ACCESS_TOKEN" == *$'\r'* ]]; then
  echo "⚠️  WARNING: Token contains newline characters"
fi

if [[ ${#ACCESS_TOKEN} -lt 100 ]]; then
  echo "⚠️  WARNING: Token seems too short (${#ACCESS_TOKEN} chars)"
elif [[ ${#ACCESS_TOKEN} -gt 2000 ]]; then
  echo "⚠️  WARNING: Token seems too long (${#ACCESS_TOKEN} chars)"
else
  echo "✅ Token length appears normal (${#ACCESS_TOKEN} chars)"
fi

# Step 2: Test current location settings retrieval
echo ""
echo "📍 Step 2: Get Current Location Settings..."

GET_RESPONSE=$(curl -s -X GET "$API_BASE/business/$BUSINESS_ID/location-settings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -w "HTTPSTATUS:%{http_code}")

# Extract HTTP status
HTTP_STATUS=$(echo "$GET_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$GET_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')

echo "📤 GET Response (Status: $HTTP_STATUS):"
if [ "$HTTP_STATUS" = "200" ]; then
  echo "$RESPONSE_BODY" | jq '.'
  echo "✅ Location settings retrieved successfully"
else
  echo "$RESPONSE_BODY"
  echo "❌ Failed to retrieve location settings (Status: $HTTP_STATUS)"
fi

# Step 3: Test location settings update
echo ""
echo "💾 Step 3: Update Location Settings..."

# Create test location data
LOCATION_DATA='{
  "city": "Baghdad",
  "district": "Karrada", 
  "street": "Test Street 123",
  "country": "Iraq",
  "latitude": 33.3152,
  "longitude": 44.3661,
  "address": "Test Street 123, Karrada, Baghdad, Iraq",
  "updated_at": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'",
  "address_components": {
    "city": {"S": "Baghdad"},
    "district": {"S": "Karrada"}, 
    "street": {"S": "Test Street 123"},
    "country": {"S": "Iraq"}
  }
}'

echo "📋 Test location data:"
echo "$LOCATION_DATA" | jq '.'

# Make the update request
UPDATE_RESPONSE=$(curl -s -X PUT "$API_BASE/business/$BUSINESS_ID/location-settings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "$LOCATION_DATA" \
  -w "HTTPSTATUS:%{http_code}")

# Extract HTTP status
HTTP_STATUS=$(echo "$UPDATE_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$UPDATE_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')

echo ""
echo "📤 UPDATE Response (Status: $HTTP_STATUS):"
if [ "$HTTP_STATUS" = "200" ]; then
  echo "$RESPONSE_BODY" | jq '.'
  echo "✅ Location settings updated successfully"
else
  echo "$RESPONSE_BODY"
  echo "❌ Failed to update location settings (Status: $HTTP_STATUS)"
  
  # Check for authorization header issues
  if echo "$RESPONSE_BODY" | grep -q "Invalid key=value pair"; then
    echo "🚨 AUTHORIZATION HEADER CORRUPTION DETECTED!"
    echo "   This indicates the token is being corrupted before reaching the backend"
  fi
fi

# Step 4: Verify the update worked
if [ "$HTTP_STATUS" = "200" ]; then
  echo ""
  echo "🔍 Step 4: Verify Update..."
  
  VERIFY_RESPONSE=$(curl -s -X GET "$API_BASE/business/$BUSINESS_ID/location-settings" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -w "HTTPSTATUS:%{http_code}")
  
  VERIFY_HTTP_STATUS=$(echo "$VERIFY_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
  VERIFY_BODY=$(echo "$VERIFY_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')
  
  echo "📤 VERIFY Response (Status: $VERIFY_HTTP_STATUS):"
  if [ "$VERIFY_HTTP_STATUS" = "200" ]; then
    echo "$VERIFY_BODY" | jq '.'
    
    # Check if our test data is there
    if echo "$VERIFY_BODY" | jq -e '.settings.city' | grep -q "Baghdad"; then
      echo "✅ Update verification successful - test data found"
    else
      echo "⚠️  Update may not have persisted correctly"
    fi
  else
    echo "$VERIFY_BODY"
    echo "❌ Verification failed (Status: $VERIFY_HTTP_STATUS)"
  fi
fi

# Summary
echo ""
echo "📊 BACKEND TEST SUMMARY"
echo "======================"

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ Location Settings Backend: WORKING"
  echo "✅ Authorization: CLEAN TOKEN SUCCESS"
  echo "✅ API Endpoints: FUNCTIONAL"
  echo ""
  echo "🎯 CONCLUSION: Backend is working correctly!"
  echo "   The issue is likely in the frontend token handling or corruption during storage/retrieval."
else
  echo "❌ Location Settings Backend: FAILED"
  echo "❌ Status Code: $HTTP_STATUS"
  echo ""
  if echo "$RESPONSE_BODY" | grep -q "Invalid key=value pair"; then
    echo "🎯 CONCLUSION: Authorization header corruption confirmed!"
    echo "   The issue is in how tokens are being formatted/sent to the backend."
  else
    echo "🎯 CONCLUSION: Backend API issue detected!"
    echo "   The problem may be in the backend logic itself."
  fi
fi

echo ""
echo "🔧 Next Steps:"
if [ "$HTTP_STATUS" = "200" ]; then
  echo "1. ✅ Backend is working - focus on frontend token management"
  echo "2. 🔍 Debug Flutter app token storage and retrieval"
  echo "3. 🧹 Ensure TokenManager is being used consistently"
  echo "4. 📱 Test location settings in Flutter app with fresh login"
else
  echo "1. 🔍 Investigate backend authorization parsing"
  echo "2. 🔧 Check API Gateway configuration"
  echo "3. 📋 Review Lambda function token validation"
fi
