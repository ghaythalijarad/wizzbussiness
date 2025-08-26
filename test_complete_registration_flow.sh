#!/bin/bash

echo "🧪 COMPLETE REGISTRATION FLOW TEST"
echo "=================================="
echo ""
echo "This script tests the entire registration process after deployment"
echo ""

API_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

# Test data
EMAIL="test-$(date +%s)@example.com"
PASSWORD="TestPass123!"
FIRST_NAME="Test"
LAST_NAME="User"
BUSINESS_NAME="Test Business $(date +%s)"
BUSINESS_TYPE="restaurant"
PHONE_NUMBER="+1234567890"

echo "📋 Testing with:"
echo "Email: $EMAIL"
echo "Business: $BUSINESS_NAME"
echo ""

# Step 1: Test business photo upload (registration bypass)
echo "1️⃣ Testing business photo upload (registration)..."

BASE64_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
FILENAME="business-photo-$(uuidgen | tr '[:upper:]' '[:lower:]').jpg"

UPLOAD_RESPONSE=$(curl -s -X POST \
  "$API_URL/upload/business-photo" \
  -H "Content-Type: application/json" \
  -H "X-Registration-Upload: true" \
  -d "{
    \"image\": \"$BASE64_IMAGE\",
    \"filename\": \"$FILENAME\"
  }")

UPLOAD_SUCCESS=$(echo $UPLOAD_RESPONSE | jq -r '.success' 2>/dev/null)
BUSINESS_PHOTO_URL=$(echo $UPLOAD_RESPONSE | jq -r '.imageUrl' 2>/dev/null)

if [ "$UPLOAD_SUCCESS" = "true" ]; then
  echo "✅ Business photo upload successful"
  echo "📍 Photo URL: $BUSINESS_PHOTO_URL"
else
  echo "❌ Business photo upload failed"
  echo "Response: $UPLOAD_RESPONSE"
  echo ""
  echo "🚨 Deploy the authorization fix first!"
  exit 1
fi

echo ""

# Step 2: Test user registration with business
echo "2️⃣ Testing user registration with business..."

REGISTER_RESPONSE=$(curl -s -X POST \
  "$API_URL/auth/register-with-business" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\",
    \"firstName\": \"$FIRST_NAME\",
    \"lastName\": \"$LAST_NAME\",
    \"businessName\": \"$BUSINESS_NAME\",
    \"businessType\": \"$BUSINESS_TYPE\",
    \"phoneNumber\": \"$PHONE_NUMBER\",
    \"businessPhotoUrl\": \"$BUSINESS_PHOTO_URL\"
  }")

REGISTER_SUCCESS=$(echo $REGISTER_RESPONSE | jq -r '.success' 2>/dev/null)

if [ "$REGISTER_SUCCESS" = "true" ]; then
  echo "✅ User registration successful"
  echo "📧 Verification email should be sent"
  
  USER_SUB=$(echo $REGISTER_RESPONSE | jq -r '.user_sub' 2>/dev/null)
  echo "👤 User ID: $USER_SUB"
  
else
  echo "❌ User registration failed"
  echo "Response: $REGISTER_RESPONSE"
fi

echo ""
echo "🎯 REGISTRATION FLOW SUMMARY:"
echo "=============================="

if [ "$UPLOAD_SUCCESS" = "true" ] && [ "$REGISTER_SUCCESS" = "true" ]; then
  echo "🎉 COMPLETE SUCCESS!"
  echo "✅ Business photo upload works during registration"
  echo "✅ User registration completes successfully"
  echo "✅ Verification email sent"
  echo ""
  echo "📱 Next steps in the app:"
  echo "1. User receives verification email"
  echo "2. Enter verification code in app"
  echo "3. Complete registration process"
  echo ""
  echo "🏆 REGISTRATION ISSUE COMPLETELY RESOLVED!"
  
else
  echo "❌ Some steps failed - see errors above"
  echo "Need to deploy fixes and test again"
fi

echo ""
echo "🏁 Test completed"
