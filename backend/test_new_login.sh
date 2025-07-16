#!/bin/bash

echo "🧪 Testing Login After Password Reset"
echo "====================================="

read -p "Enter your new password: " -s NEW_PASSWORD
echo ""
echo ""

echo "🔄 Testing login with new password..."

RESPONSE=$(curl -s -X POST https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/auth/signin \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"g87_a@yahoo.com\", \"password\": \"$NEW_PASSWORD\"}")

echo "Backend Response:"
echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo ""
    echo "✅ LOGIN SUCCESSFUL!"
    echo "🎉 Your authentication is now working!"
else
    echo ""
    echo "❌ Login still failing. Let's check the error..."
fi
