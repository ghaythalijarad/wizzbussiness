#!/bin/bash

echo "📧 Email Verification Code Helper"
echo "================================="
echo ""

API_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

# Get email from user
echo "What email address did you use during registration?"
read -p "Email: " EMAIL

if [ -z "$EMAIL" ]; then
    echo "❌ Email is required"
    exit 1
fi

echo ""
echo "🔍 Checking email status and resending verification code..."

# Try to resend verification code
RESEND_RESPONSE=$(curl -s -X POST \
  "$API_URL/auth/resend-code" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\"
  }")

echo "Resend response: $RESEND_RESPONSE"

SUCCESS=$(echo $RESEND_RESPONSE | jq -r '.success' 2>/dev/null)

if [ "$SUCCESS" = "true" ]; then
    echo ""
    echo "✅ Verification code resent successfully!"
    echo "📧 Check your email (including spam/junk folder)"
    echo ""
    echo "📱 In your Flutter app:"
    echo "1. Go to the verification screen"
    echo "2. Enter the 6-digit code from the email"
    echo "3. Complete registration"
    
else
    echo ""
    echo "❌ Failed to resend verification code"
    MESSAGE=$(echo $RESEND_RESPONSE | jq -r '.message' 2>/dev/null)
    echo "Error: $MESSAGE"
    echo ""
    echo "🛠️ TROUBLESHOOTING:"
    echo ""
    echo "1. Check if email is correct:"
    echo "   Email entered: $EMAIL"
    echo ""
    echo "2. Check spam/junk folder"
    echo ""
    echo "3. Wait a few minutes and try again"
    echo ""
    echo "4. Try registering with a different email if needed"
fi

echo ""
echo "🏁 Email verification helper completed"
