#!/bin/bash

echo "📧 COMPREHENSIVE EMAIL VERIFICATION TEST"
echo "========================================"
echo ""

API_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
EMAIL="write2ghayth@gmail.com"

echo "Testing email verification for: $EMAIL"
echo ""

# Test 1: Check if user exists
echo "1️⃣ Checking if user exists..."
USER_CHECK_RESPONSE=$(curl -s -X POST \
  "$API_URL/auth/check-email" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\"}")

echo "User check response: $USER_CHECK_RESPONSE"
echo ""

# Test 2: Try resend verification code
echo "2️⃣ Testing resend verification code..."
RESEND_RESPONSE=$(curl -s -X POST \
  "$API_URL/auth/resend-code" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\"}")

echo "Resend response: $RESEND_RESPONSE"
echo ""

# Test 3: Test registration with fresh email
TEST_EMAIL="test-$(date +%s)@gmail.com"
echo "3️⃣ Testing fresh registration with email: $TEST_EMAIL"

REGISTER_RESPONSE=$(curl -s -X POST \
  "$API_URL/auth/register-with-business" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"TestPass123!\",
    \"firstName\": \"Test\",
    \"lastName\": \"User\",
    \"businessName\": \"Test Business $(date +%s)\",
    \"businessType\": \"restaurant\",
    \"phoneNumber\": \"+1234567890\"
  }")

echo "Registration response: $REGISTER_RESPONSE"
echo ""

# Extract verification details
SUCCESS=$(echo $REGISTER_RESPONSE | jq -r '.success' 2>/dev/null)
DELIVERY_DETAILS=$(echo $REGISTER_RESPONSE | jq -r '.code_delivery_details' 2>/dev/null)

if [ "$SUCCESS" = "true" ]; then
    echo "✅ Registration successful"
    echo "📧 Delivery details: $DELIVERY_DETAILS"
    
    # Test resend for the new email
    echo ""
    echo "4️⃣ Testing resend for new registration..."
    NEW_RESEND_RESPONSE=$(curl -s -X POST \
      "$API_URL/auth/resend-code" \
      -H "Content-Type: application/json" \
      -d "{\"email\": \"$TEST_EMAIL\"}")
    
    echo "New resend response: $NEW_RESEND_RESPONSE"
else
    echo "❌ Registration failed"
fi

echo ""
echo "🔍 ANALYSIS:"
echo "============"

# Check what type of verification is being used
if echo "$RESEND_RESPONSE" | grep -q "SMS"; then
    echo "⚠️  ISSUE FOUND: Verification is being sent via SMS, not email"
    echo "📱 Phone number: $(echo $RESEND_RESPONSE | jq -r '.code_delivery_details.Destination' 2>/dev/null)"
    echo ""
    echo "💡 SOLUTION: Check your phone for SMS verification code"
elif echo "$RESEND_RESPONSE" | grep -q "EMAIL"; then
    echo "✅ Email verification is configured correctly"
    echo "📧 Check your email (including spam folder)"
else
    echo "⚠️  Unclear verification method - check both email and phone"
fi

echo ""
echo "🏁 Email verification test completed"
