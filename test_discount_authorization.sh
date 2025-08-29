#!/bin/bash

echo "🧪 Testing Discount Management Authorization Fix"
echo "================================================"

# Get tokens
echo "🔐 Getting authentication tokens..."
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

# Use ID token for API Gateway (our fix!)
TOKEN="$ID_TOKEN"
echo "🎫 Using ID token for testing (contains required 'aud' field)"

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
  
  # Count discounts
  DISCOUNT_COUNT=$(echo "$RESPONSE_BODY" | jq -r '.discounts | length' 2>/dev/null || echo "0")
  echo "📊 Found $DISCOUNT_COUNT discounts"
  
  if [ "$DISCOUNT_COUNT" != "null" ] && [ "$DISCOUNT_COUNT" != "0" ]; then
    echo "💰 Discounts loaded successfully!"
  else
    echo "ℹ️ No discounts found (which is OK for testing)"
  fi
  
elif [ "$HTTP_STATUS" = "401" ]; then
  echo "❌ Still getting 401 Unauthorized - authorization fix needed"
else
  echo "ℹ️ HTTP Status: $HTTP_STATUS"
fi

echo ""
echo "🏁 Discount Management Test Complete"
