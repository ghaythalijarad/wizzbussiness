#!/bin/bash

# Deploy Location Settings Fix
# This fixes the authorization header corruption issue by adding the missing location settings endpoints

echo "🔧 DEPLOYING LOCATION SETTINGS FIX"
echo "=================================="
echo "Issue: Missing backend endpoints causing authorization header corruption errors"
echo "Solution: Adding complete location settings API endpoints and Lambda handler"
echo ""

# Set AWS profile and check credentials
export AWS_PROFILE=wizz-merchants-dev
echo "🔐 AWS Profile: $AWS_PROFILE"

# Verify AWS credentials
echo "🔍 Verifying AWS credentials..."
aws sts get-caller-identity --profile $AWS_PROFILE
if [ $? -ne 0 ]; then
    echo "❌ AWS credentials not valid. Please run: aws sso login --profile $AWS_PROFILE"
    exit 1
fi

echo "✅ AWS credentials verified"
echo ""

# Build and deploy
echo "🏗️ Building SAM application..."
cd backend
sam build

if [ $? -ne 0 ]; then
    echo "❌ SAM build failed"
    exit 1
fi

echo "✅ SAM build successful"
echo ""

echo "🚀 Deploying to AWS..."
sam deploy --no-confirm-changeset

if [ $? -ne 0 ]; then
    echo "❌ SAM deployment failed"
    exit 1
fi

echo "✅ Deployment successful!"
echo ""

# Test the fix
echo "🧪 Testing location settings endpoints..."

# Get API endpoint
API_ENDPOINT="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
BUSINESS_ID="business_1756220656049_ee98qktepks"

# Test authentication first
echo "🔐 Testing authentication..."
AUTH_RESPONSE=$(curl -s -X POST "$API_ENDPOINT/auth/signin" \
  -H "Content-Type: application/json" \
  -d '{"email": "g87_a@yahoo.com", "password": "Gha@551987"}')

ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.data.AccessToken // empty')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo "❌ Authentication failed"
  echo "$AUTH_RESPONSE"
  exit 1
fi

echo "✅ Authentication successful"
echo ""

# Test GET location settings
echo "📍 Testing GET location settings..."
GET_RESPONSE=$(curl -s -X GET "$API_ENDPOINT/businesses/$BUSINESS_ID/location-settings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

echo "📤 GET Response:"
echo "$GET_RESPONSE" | jq '.'

if echo "$GET_RESPONSE" | jq -e '.success' >/dev/null 2>&1; then
  echo "✅ GET location settings: SUCCESS"
else
  echo "❌ GET location settings: FAILED"
fi

echo ""

# Test PUT location settings
echo "📍 Testing PUT location settings..."
PUT_DATA='{
  "city": "Baghdad",
  "district": "Karrada",
  "street": "Test Street 123",
  "country": "Iraq",
  "latitude": 33.3152,
  "longitude": 44.3661,
  "address": "Test Street 123, Karrada, Baghdad, Iraq"
}'

PUT_RESPONSE=$(curl -s -X PUT "$API_ENDPOINT/businesses/$BUSINESS_ID/location-settings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "$PUT_DATA")

echo "📤 PUT Response:"
echo "$PUT_RESPONSE" | jq '.'

if echo "$PUT_RESPONSE" | jq -e '.success' >/dev/null 2>&1; then
  echo "✅ PUT location settings: SUCCESS"
else
  echo "❌ PUT location settings: FAILED"
fi

echo ""
echo "🎯 DEPLOYMENT SUMMARY"
echo "===================="

if echo "$GET_RESPONSE" | jq -e '.success' >/dev/null 2>&1 && echo "$PUT_RESPONSE" | jq -e '.success' >/dev/null 2>&1; then
  echo "✅ Location Settings Fix: SUCCESSFUL"
  echo "✅ Authorization Header Issue: RESOLVED"
  echo "✅ API Endpoints: WORKING"
  echo ""
  echo "🎉 The location settings functionality is now working correctly!"
  echo "   The 'Invalid key=value pair' error has been resolved."
  echo ""
  echo "📱 Next Steps:"
  echo "1. Test in the Flutter app"
  echo "2. Verify location settings save and retrieve correctly"
  echo "3. Confirm no more authorization header corruption errors"
else
  echo "❌ Location Settings Fix: FAILED"
  echo "   Please check the error messages above"
fi

echo ""
echo "📊 TECHNICAL DETAILS"
echo "==================="
echo "✅ Added: /businesses/{businessId}/location-settings endpoints"
echo "✅ Added: /businesses/{businessId}/working-hours endpoints" 
echo "✅ Added: LocationSettingsFunction Lambda handler"
echo "✅ Added: Proper DynamoDB permissions"
echo "✅ Added: API Gateway routing and CORS"
echo ""
echo "🔧 Files Modified:"
echo "   - backend/functions/business/location_settings_handler.js (CREATED)"
echo "   - backend/template.yaml (UPDATED with endpoints and function)"
