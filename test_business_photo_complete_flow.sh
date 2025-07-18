#!/bin/bash
# Test complete business photo integration flow

set -e

API_BASE="https://clgs5798k1.execute-api.eu-north-1.amazonaws.com/dev"

# Test data
TEST_EMAIL="business_photo_test_$(date +%s)@example.com"
TEST_BUSINESS_NAME="Test Business Photo $(date +%s)"
TEST_PASSWORD="TempPass123!"

echo "=== Testing Complete Business Photo Integration ==="
echo "Email: $TEST_EMAIL"
echo "Business: $TEST_BUSINESS_NAME"

# Step 1: Upload business photo first
echo -e "\n1. Uploading business photo..."
UPLOAD_RESPONSE=$(curl -s -X POST \
  "$API_BASE/upload/business-photo" \
  -H "Content-Type: application/json" \
  -H "x-upload-type: business-photo" \
  -d '{
    "image": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k="
  }')

echo "Upload response: $UPLOAD_RESPONSE"

# Extract image URL
BUSINESS_PHOTO_URL=$(echo "$UPLOAD_RESPONSE" | grep -o '"imageUrl":"[^"]*"' | sed 's/"imageUrl":"//' | sed 's/"//')

if [ -z "$BUSINESS_PHOTO_URL" ]; then
  echo "ERROR: Failed to upload business photo"
  exit 1
fi

echo "Business photo uploaded: $BUSINESS_PHOTO_URL"

# Step 2: Test photo URL accessibility
echo -e "\n2. Testing photo URL accessibility..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BUSINESS_PHOTO_URL")

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ Business photo is publicly accessible"
else
  echo "❌ Business photo is not accessible (HTTP $HTTP_STATUS)"
  exit 1
fi

# Step 3: Register business with photo URL
echo -e "\n3. Registering business with photo URL..."
REGISTER_RESPONSE=$(curl -s -X POST \
  "$API_BASE/auth/register-with-business" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\",
    \"businessName\": \"$TEST_BUSINESS_NAME\",
    \"businessType\": \"Restaurant\",
    \"ownerName\": \"Test Owner\",
    \"businessPhotoUrl\": \"$BUSINESS_PHOTO_URL\"
  }")

echo "Registration response: $REGISTER_RESPONSE"

# Check if registration was successful
if echo "$REGISTER_RESPONSE" | grep -q '"success":true'; then
  echo "✅ Business registration with photo successful"
else
  echo "❌ Business registration failed"
  exit 1
fi

echo -e "\n=== Business Photo Integration Test Complete ==="
echo "✅ All tests passed!"
echo "Business photo URL: $BUSINESS_PHOTO_URL"
echo "Business registered with photo: $TEST_BUSINESS_NAME"
