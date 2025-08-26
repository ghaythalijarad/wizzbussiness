#!/bin/bash

echo "🔍 EMAIL VERIFICATION TROUBLESHOOTING"
echo "===================================="
echo ""

API_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

echo "1️⃣ Testing registration endpoint response..."
echo ""

# Test registration with a test email
TEST_EMAIL="debug-email-$(date +%s)@gmail.com"
echo "Test email: $TEST_EMAIL"
echo ""

REGISTER_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" -X POST \
  "$API_URL/auth/register-with-business" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"TestPass123!\",
    \"firstName\": \"Debug\",
    \"lastName\": \"User\",
    \"businessName\": \"Debug Business\",
    \"businessType\": \"restaurant\",
    \"phoneNumber\": \"+1234567890\"
  }")

echo "Registration Response:"
echo "$REGISTER_RESPONSE"
echo ""

# Extract HTTP code and response body
HTTP_CODE=$(echo "$REGISTER_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$REGISTER_RESPONSE" | grep -v "HTTP_CODE:")

echo "HTTP Status Code: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Registration endpoint responded successfully"
    
    # Check if response indicates email was sent
    SUCCESS=$(echo "$RESPONSE_BODY" | jq -r '.success' 2>/dev/null)
    MESSAGE=$(echo "$RESPONSE_BODY" | jq -r '.message' 2>/dev/null)
    
    echo "Success: $SUCCESS"
    echo "Message: $MESSAGE"
    
    if [ "$SUCCESS" = "true" ]; then
        echo ""
        echo "✅ Registration successful - verification email should be sent"
        echo ""
        echo "🔍 POSSIBLE ISSUES:"
        echo "1. Check spam/junk folder"
        echo "2. Cognito email configuration issue"
        echo "3. SES email limits or verification needed"
        echo "4. Email address format validation"
        echo ""
        echo "📧 EMAIL DELIVERY TROUBLESHOOTING:"
        echo "- Try with a Gmail address"
        echo "- Check AWS SES sending statistics"
        echo "- Verify Cognito email configuration"
        
    else
        echo ""
        echo "❌ Registration failed"
        echo "This could explain why no email is sent"
    fi
    
else
    echo "❌ Registration endpoint error (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
fi

echo ""
echo "2️⃣ Testing resend verification code..."
echo ""

# Test resend code with your actual email
YOUR_EMAIL="ghaythal.laheebi@gmail.com"  # Replace with your actual email

RESEND_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" -X POST \
  "$API_URL/auth/resend-code" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$YOUR_EMAIL\"
  }")

echo "Resend Code Response:"
echo "$RESEND_RESPONSE"
echo ""

HTTP_CODE_RESEND=$(echo "$RESEND_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
RESEND_BODY=$(echo "$RESEND_RESPONSE" | grep -v "HTTP_CODE:")

echo "HTTP Status Code: $HTTP_CODE_RESEND"

if [ "$HTTP_CODE_RESEND" = "200" ]; then
    echo "✅ Resend code endpoint working"
    echo "Check your email (including spam folder)"
else
    echo "❌ Resend code failed"
    echo "Response: $RESEND_BODY"
fi

echo ""
echo "🎯 NEXT STEPS:"
echo "=============="
echo ""
echo "If registration succeeded but no email:"
echo "1. Check spam/junk folder thoroughly"
echo "2. Try registering with a different email provider"
echo "3. Use the resend code feature"
echo "4. Check AWS SES configuration"
echo ""
echo "If you have a verification code:"
echo "1. Use it in the app to complete verification"
echo "2. Or test with: curl -X POST $API_URL/auth/confirm"
