#!/bin/bash

# Test real business photo registration flow
# This script tests the complete corrected flow from photo upload to database storage

echo "🧪 Testing Real Business Photo Registration Flow"
echo "================================================="

API_URL="https://clgs5798k1.execute-api.eu-north-1.amazonaws.com/dev"
TEST_EMAIL="test-business-photo-$(date +%s)@example.com"
TEST_PASSWORD="TestPassword123!"
TEST_BUSINESS_NAME="Real Photo Test Business $(date +%s)"

echo "📧 Test email: $TEST_EMAIL"
echo "🏢 Test business: $TEST_BUSINESS_NAME"
echo ""

# Step 1: Upload business photo to correct endpoint
echo "📸 Step 1: Uploading business photo to /upload/business-photo..."
UPLOAD_RESPONSE=$(curl -s -X POST "$API_URL/upload/business-photo" \
  -F "image=@test_image.png" \
  -H "Content-Type: multipart/form-data")

echo "Upload response: $UPLOAD_RESPONSE"

# Extract the business photo URL
BUSINESS_PHOTO_URL=$(echo $UPLOAD_RESPONSE | grep -o '"imageUrl":"[^"]*"' | cut -d'"' -f4)

if [ -z "$BUSINESS_PHOTO_URL" ]; then
  echo "❌ FAILED: No business photo URL returned"
  exit 1
fi

echo "✅ Business photo uploaded successfully"
echo "🔗 Photo URL: $BUSINESS_PHOTO_URL"
echo ""

# Step 2: Verify photo is accessible
echo "🌐 Step 2: Verifying photo accessibility..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BUSINESS_PHOTO_URL")

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ Photo is publicly accessible (HTTP $HTTP_STATUS)"
else
  echo "❌ FAILED: Photo not accessible (HTTP $HTTP_STATUS)"
  exit 1
fi
echo ""

# Step 3: Register business with photo URL
echo "🔧 Step 3: Registering business with photo URL..."
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/auth/register-with-business" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\",
    \"businessName\": \"$TEST_BUSINESS_NAME\",
    \"businessType\": \"restaurant\",
    \"businessPhotoUrl\": \"$BUSINESS_PHOTO_URL\"
  }")

echo "Registration response: $REGISTER_RESPONSE"

# Extract business ID from response
BUSINESS_ID=$(echo $REGISTER_RESPONSE | grep -o '"businessId":"[^"]*"' | cut -d'"' -f4)

if [ -z "$BUSINESS_ID" ]; then
  echo "❌ FAILED: No business ID returned from registration"
  exit 1
fi

echo "✅ Business registered successfully"
echo "🆔 Business ID: $BUSINESS_ID"
echo ""

# Step 4: Wait a moment for database consistency
echo "⏳ Step 4: Waiting for database consistency..."
sleep 3
echo ""

# Step 5: Verify business photo URL is saved in DynamoDB
echo "🗄️ Step 5: Verifying business photo URL in DynamoDB..."
DYNAMO_RESULT=$(aws dynamodb get-item \
  --region us-east-1 \
  --table-name order-receiver-businesses-dev \
  --key "{\"businessId\":{\"S\":\"$BUSINESS_ID\"}}" \
  --projection-expression "business_id, business_name, business_photo_url" \
  --output json 2>/dev/null)

echo "DynamoDB result: $DYNAMO_RESULT"

# Check if business_photo_url exists in DynamoDB
SAVED_PHOTO_URL=$(echo $DYNAMO_RESULT | grep -o '"business_photo_url":{"S":"[^"]*"' | cut -d'"' -f6)

if [ -z "$SAVED_PHOTO_URL" ]; then
  echo "❌ FAILED: business_photo_url not found in DynamoDB"
  exit 1
fi

if [ "$SAVED_PHOTO_URL" = "$BUSINESS_PHOTO_URL" ]; then
  echo "✅ Business photo URL correctly saved in DynamoDB"
  echo "📷 Saved URL: $SAVED_PHOTO_URL"
else
  echo "❌ FAILED: Photo URL mismatch"
  echo "Expected: $BUSINESS_PHOTO_URL"
  echo "Found: $SAVED_PHOTO_URL"
  exit 1
fi
echo ""

# Step 6: Final verification - check photo accessibility from saved URL
echo "🔍 Step 6: Final verification - checking saved photo URL..."
SAVED_HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SAVED_PHOTO_URL")

if [ "$SAVED_HTTP_STATUS" = "200" ]; then
  echo "✅ Saved photo URL is accessible (HTTP $SAVED_HTTP_STATUS)"
else
  echo "❌ WARNING: Saved photo URL not accessible (HTTP $SAVED_HTTP_STATUS)"
fi
echo ""

echo "🎉 SUCCESS! Complete Business Photo Registration Flow Working!"
echo "============================================================="
echo "✅ Photo upload: WORKING"
echo "✅ Photo accessibility: WORKING" 
echo "✅ Business registration: WORKING"
echo "✅ Database storage: WORKING"
echo "✅ End-to-end flow: WORKING"
echo ""
echo "📊 Test Results:"
echo "  Business ID: $BUSINESS_ID"
echo "  Business Name: $TEST_BUSINESS_NAME"
echo "  Photo URL: $BUSINESS_PHOTO_URL"
echo "  Status: All systems operational ✅"
