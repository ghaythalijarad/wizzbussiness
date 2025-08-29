#!/bin/bash

echo "🔍 Debug Discount Token Issue"
echo "=============================="

# Get token
echo "🔐 Getting tokens..."
AUTH_RESPONSE=$(curl -s -X POST "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/signin" \
  -H "Content-Type: application/json" \
  -d '{"email": "g87_a@yahoo.com", "password": "Gha@551987"}')

ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.data.AccessToken')
ID_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.data.IdToken')

echo "✅ Access token length: ${#ACCESS_TOKEN}"
echo "✅ ID token length: ${#ID_TOKEN}"

# Use ID token
TOKEN="$ID_TOKEN"

# Check for any special characters that might cause issues
echo ""
echo "🔍 Token Analysis:"
echo "First 50 chars: ${TOKEN:0:50}..."
echo "Last 50 chars: ...${TOKEN: -50}"

# Check if token contains any equals signs (which might confuse the parser)
EQUALS_COUNT=$(echo "$TOKEN" | grep -o "=" | wc -l | tr -d ' ')
echo "Equals signs in token: $EQUALS_COUNT"

# Check for any suspicious characters
if echo "$TOKEN" | grep -q "[^A-Za-z0-9._-]"; then
    echo "⚠️  Token contains special characters that might cause issues"
else
    echo "✅ Token looks clean (only alphanumeric, dots, underscores, dashes)"
fi

# Try the API call with verbose curl to see exactly what's being sent
echo ""
echo "📊 Testing GET /discounts with verbose output..."
curl -v \
  -X GET "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/discounts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  2>&1 | head -30

echo ""
echo "🔍 Debug complete"
