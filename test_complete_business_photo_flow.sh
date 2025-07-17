#!/bin/bash

# Test complete business photo flow
echo "🔄 Testing Complete Business Photo Flow"
echo "====================================="

# Step 1: Upload business photo
echo "Step 1: Uploading business photo..."
UPLOAD_RESPONSE=$(curl -s -X POST https://clgs5798k1.execute-api.eu-north-1.amazonaws.com/dev/upload/product-image \
  -H "x-upload-type: business-photo" \
  -F "image=@test_image.png")

echo "Upload Response: $UPLOAD_RESPONSE"

# Extract image URL from response
BUSINESS_PHOTO_URL=$(echo $UPLOAD_RESPONSE | grep -o '"imageUrl":"[^"]*"' | cut -d'"' -f4)

if [ -z "$BUSINESS_PHOTO_URL" ]; then
    echo "❌ Failed to upload business photo"
    exit 1
fi

echo "✅ Business photo uploaded: $BUSINESS_PHOTO_URL"

# Step 2: Register with the uploaded photo URL
echo ""
echo "Step 2: Registering with business photo..."
TIMESTAMP=$(date +%s)
EMAIL="complete_test_${TIMESTAMP}@example.com"

REGISTER_RESPONSE=$(curl -s -X POST https://clgs5798k1.execute-api.eu-north-1.amazonaws.com/dev/auth/register-with-business \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"TestPass123!\",
    \"businessName\": \"Complete Test Business\",
    \"businessType\": \"restaurant\",
    \"phoneNumber\": \"07700000000\",
    \"firstName\": \"Complete\",
    \"lastName\": \"Test\",
    \"address\": \"Test Street\",
    \"city\": \"Baghdad\",
    \"district\": \"Test District\",
    \"country\": \"Iraq\",
    \"businessPhotoUrl\": \"$BUSINESS_PHOTO_URL\"
  }")

echo "Registration Response: $REGISTER_RESPONSE"

# Extract business ID
BUSINESS_ID=$(echo $REGISTER_RESPONSE | grep -o '"business_id":"[^"]*"' | cut -d'"' -f4)

if [ -z "$BUSINESS_ID" ]; then
    echo "❌ Registration failed"
    exit 1
fi

echo "✅ Registration successful with Business ID: $BUSINESS_ID"

# Step 3: Verify in DynamoDB
echo ""
echo "Step 3: Verifying in DynamoDB..."
sleep 3  # Wait for propagation

aws dynamodb get-item --table-name order-receiver-businesses-dev --region us-east-1 \
  --key "{\"businessId\": {\"S\": \"$BUSINESS_ID\"}}" \
  --projection-expression "business_name, business_photo_url, email" \
  --no-cli-pager

echo ""
echo "🎉 Complete business photo flow test finished!"
echo "Email: $EMAIL"
echo "Business ID: $BUSINESS_ID"
echo "Photo URL: $BUSINESS_PHOTO_URL"
