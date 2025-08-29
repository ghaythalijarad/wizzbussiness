#!/bin/bash

echo "🎯 Discount Management Authorization Test"
echo "========================================"

# Get token
echo "🔐 Getting tokens..."
AUTH_RESPONSE=$(curl -s -X POST "https://m90p0zj1g1.execute-api.us-east-1.amazonaws.com/dev/auth/signin" \
  -H "Content-Type: application/json" \
  -d '{"email": "g87_a@yahoo.com", "password": "Gha@551987"}')

ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.data.AccessToken')
ID_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.data.IdToken')

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Failed to get tokens"
  echo "Response: $AUTH_RESPONSE"
  exit 1
fi

echo "✅ Access token obtained (length: ${#ACCESS_TOKEN})"
echo "✅ ID token obtained (length: ${#ID_TOKEN})"

# Use ID token for API Gateway (same fix as location settings!)
TOKEN="$ID_TOKEN"
echo "🎫 Using ID token for testing (contains required 'aud' field)"

# Test GET discounts
echo ""
echo "💰 Testing GET /discounts..."
GET_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X GET "https://m90p0zj1g1.execute-api.us-east-1.amazonaws.com/dev/discounts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

HTTP_STATUS=$(echo "$GET_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$GET_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')

echo "Status: $HTTP_STATUS"
echo "Response: $RESPONSE_BODY"

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ GET discounts: SUCCESS"
  echo "🎉 Discount authorization FIXED!"
elif [ "$HTTP_STATUS" = "404" ]; then
  echo "⚠️  404 Not Found - Discount endpoints not yet deployed"
  echo "📋 Need to deploy backend changes first"
elif [ "$HTTP_STATUS" = "403" ]; then
  echo "❌ 403 Forbidden - Authorization issue (same as before)"
elif [ "$HTTP_STATUS" = "401" ]; then
  echo "❌ 401 Unauthorized - Token issue"
else
  echo "ℹ️ HTTP Status: $HTTP_STATUS"
fi

echo ""
echo "🏁 DISCOUNT TEST COMPLETE"
echo "========================="

if [ "$HTTP_STATUS" = "200" ]; then
  echo "🎉 SUCCESS: Discount management authorization is working!"
elif [ "$HTTP_STATUS" = "404" ]; then
  echo "📋 NEXT STEP: Deploy backend changes to add discount endpoints"
  echo "   Run: cd backend && sam deploy --no-confirm-changeset"
else
  echo "❌ ISSUE: Still have authorization problems"
fi
