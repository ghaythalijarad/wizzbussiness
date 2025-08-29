#!/bin/bash

echo "🎯 Discount Management API Test"
echo "==============================="

# Get token
echo "🔐 Getting tokens..."
AUTH_RESPONSE=$(curl -s -X POST "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/signin" \
  -H "Content-Type: application/json" \
  -d '{"email": "g87_a@yahoo.com", "password": "Gha@551987"}')

ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.data.AccessToken')
ID_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.data.IdToken')

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Failed to get access token"
  echo "Response: $AUTH_RESPONSE"
  exit 1
fi

echo "✅ Access token obtained (length: ${#ACCESS_TOKEN})"
echo "✅ ID token obtained (length: ${#ID_TOKEN})"

# Use ID token for API Gateway (our TokenManager fix!)
TOKEN="$ID_TOKEN"
echo "🎫 Using ID token for testing (contains required 'aud' field)"

# Test GET discounts
echo ""
echo "📊 Testing GET /discounts..."
GET_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X GET "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/discounts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

HTTP_STATUS=$(echo "$GET_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$GET_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')

echo "Status: $HTTP_STATUS"
echo "Response: $RESPONSE_BODY"

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ GET discounts: SUCCESS"
  
  # Parse the response to count discounts
  DISCOUNT_COUNT=$(echo "$RESPONSE_BODY" | jq -r '.count // 0')
  echo "📈 Found $DISCOUNT_COUNT discounts"
  
elif [ "$HTTP_STATUS" = "401" ]; then
  echo "❌ Still getting 401 Unauthorized - Token issue"
  echo "🔍 Debug Info:"
  echo "   - Access Token Length: ${#ACCESS_TOKEN}"
  echo "   - ID Token Length: ${#ID_TOKEN}"
  echo "   - Using: ID Token"
  exit 1
elif [ "$HTTP_STATUS" = "404" ]; then
  echo "❌ 404 Not Found - Endpoint might not exist"
  exit 1
else
  echo "ℹ️ HTTP Status: $HTTP_STATUS"
fi

# Test CREATE discount
echo ""
echo "📊 Testing POST /discounts (Create)..."
DISCOUNT_DATA='{
  "title": "Test Discount",
  "description": "API Test Discount",
  "type": "percentage",
  "value": 10,
  "applicability": "allItems",
  "validFrom": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'",
  "validTo": "'$(date -u -v+30d +"%Y-%m-%dT%H:%M:%S.000Z")'",
  "minimumOrderAmount": 0,
  "status": "active"
}'

CREATE_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X POST "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/discounts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$DISCOUNT_DATA")

HTTP_STATUS=$(echo "$CREATE_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$CREATE_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')

echo "Status: $HTTP_STATUS"
echo "Response: $RESPONSE_BODY"

if [ "$HTTP_STATUS" = "201" ]; then
  echo "✅ CREATE discount: SUCCESS"
  
  # Extract discount ID for further testing
  DISCOUNT_ID=$(echo "$RESPONSE_BODY" | jq -r '.discount.discountId // .discount.id')
  echo "📝 Created discount ID: $DISCOUNT_ID"
  
  # Test UPDATE discount
  echo ""
  echo "📊 Testing PUT /discounts/{id} (Update)..."
  UPDATE_DATA='{
    "title": "Updated Test Discount",
    "value": 15
  }'
  
  UPDATE_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
    -X PUT "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/discounts/$DISCOUNT_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$UPDATE_DATA")
  
  HTTP_STATUS=$(echo "$UPDATE_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
  RESPONSE_BODY=$(echo "$UPDATE_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')
  
  echo "Status: $HTTP_STATUS"
  echo "Response: $RESPONSE_BODY"
  
  if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ UPDATE discount: SUCCESS"
  else
    echo "❌ UPDATE discount failed"
  fi
  
  # Test DELETE discount
  echo ""
  echo "📊 Testing DELETE /discounts/{id}..."
  DELETE_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
    -X DELETE "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/discounts/$DISCOUNT_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json")
  
  HTTP_STATUS=$(echo "$DELETE_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
  RESPONSE_BODY=$(echo "$DELETE_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')
  
  echo "Status: $HTTP_STATUS"
  echo "Response: $RESPONSE_BODY"
  
  if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ DELETE discount: SUCCESS"
  else
    echo "❌ DELETE discount failed"
  fi
  
elif [ "$HTTP_STATUS" = "401" ]; then
  echo "❌ CREATE discount: 401 Unauthorized"
elif [ "$HTTP_STATUS" = "404" ]; then
  echo "❌ CREATE discount: 404 Not Found - Endpoint might not exist"
else
  echo "❌ CREATE discount failed with status: $HTTP_STATUS"
fi

echo ""
echo "🏁 DISCOUNT MANAGEMENT TEST COMPLETE"
echo "====================================="

if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "201" ]; then
  echo "🎉 SUCCESS: Discount management is working with TokenManager (ID tokens)!"
  echo "✅ The authorization issue has been fixed"
else
  echo "❌ ISSUE: Discount management still has authorization problems"
  echo "🔧 Check if discount endpoints exist in API Gateway and backend"
fi
