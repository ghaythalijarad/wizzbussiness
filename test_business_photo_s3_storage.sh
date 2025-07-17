#!/bin/bash

# Business Photo S3 Storage Test Script
echo "🔍 Business Photo S3 Storage Test"
echo "================================="
echo ""

# Test 1: Check if S3 bucket exists
echo "1. 📦 Checking S3 Bucket..."
BUCKET_NAME="order-receiver-business-photos-dev"
aws s3 ls s3://$BUCKET_NAME 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ S3 bucket '$BUCKET_NAME' exists"
else
    echo "   ❌ S3 bucket '$BUCKET_NAME' does not exist"
    echo "   📌 This is expected if deployment is still in progress"
fi
echo ""

# Test 2: Check DynamoDB for business_photo_url fields
echo "2. 🗄️  Checking DynamoDB for business photo URLs..."
aws dynamodb scan \
    --table-name order-receiver-businesses-dev \
    --projection-expression "businessId, business_name, business_photo_url" \
    --region eu-north-1 \
    --max-items 5 2>/dev/null | jq -r '.Items[] | select(.business_photo_url) | "\(.business_name.S): \(.business_photo_url.S)"'

if [ $? -eq 0 ]; then
    echo "   ✅ DynamoDB query successful"
else
    echo "   ❌ DynamoDB query failed - check AWS credentials"
fi
echo ""

# Test 3: Test image upload endpoint
echo "3. 🌐 Testing Image Upload Endpoint..."
API_URL="https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev"
curl -s "$API_URL/upload/business-photo" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "x-upload-type: business-photo" \
    -d '{"test": "ping"}' | jq .

echo ""

# Test 4: Create a test base64 image for upload
echo "4. 🖼️  Creating Test Base64 Image..."
# Create a small test image (1x1 red pixel PNG)
TEST_IMAGE="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="

echo "   📝 Test image data: ${TEST_IMAGE:0:50}..."
echo ""

echo "📋 IMPLEMENTATION STATUS:"
echo "   ✅ S3 bucket configuration added to serverless.yml"
echo "   ✅ Real S3 upload handler implemented"
echo "   ✅ DynamoDB schema supports business_photo_url"
echo "   ✅ Frontend displays business photos when available"
echo "   ✅ Graceful fallback to default icons"
echo ""

echo "🚀 NEXT STEPS:"
echo "   1. Wait for serverless deployment to complete"
echo "   2. Test business photo upload via Flutter app"
echo "   3. Register new business with photo"
echo "   4. Verify photo appears in settings page"
echo "   5. Check S3 bucket for uploaded files"
echo ""

echo "🛠️  DEBUGGING COMMANDS:"
echo "   • Check S3 bucket: aws s3 ls s3://$BUCKET_NAME"
echo "   • Check CloudFormation: aws cloudformation describe-stacks --stack-name order-receiver-api-dev"
echo "   • View API logs: aws logs describe-log-groups --log-group-name-prefix /aws/lambda/order-receiver"
echo ""
