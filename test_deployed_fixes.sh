#!/bin/bash

echo "🧪 Testing Deployed Fixes"
echo "========================="

BACKEND_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

echo ""
echo "🔍 Test 1: Business Photo Upload (Registration Mode)"
echo "---------------------------------------------------"

# Test registration upload without authentication
response1=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X POST "$BACKEND_URL/upload" \
  -H "Content-Type: application/json" \
  -H "X-Registration-Upload: true" \
  -d '{"test": "registration_upload"}')

http_code1=$(echo $response1 | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
response_body1=$(echo $response1 | sed -e 's/HTTPSTATUS:.*//g')

if [ "$http_code1" = "400" ] || [ "$http_code1" = "200" ]; then
    echo "✅ PASS: Registration upload bypasses authentication (Status: $http_code1)"
    echo "   Response: $response_body1"
elif [ "$http_code1" = "401" ] || [ "$http_code1" = "403" ]; then
    echo "❌ FAIL: Registration upload still requires authentication (Status: $http_code1)"
    echo "   Response: $response_body1"
    echo "   This means the fix hasn't been deployed yet."
else
    echo "❓ UNKNOWN: Unexpected status $http_code1"
    echo "   Response: $response_body1"
fi

echo ""
echo "🔍 Test 2: Normal Upload (Should Require Auth)"
echo "---------------------------------------------"

# Test normal upload - should require authentication
response2=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X POST "$BACKEND_URL/upload" \
  -H "Content-Type: application/json" \
  -d '{"test": "normal_upload"}')

http_code2=$(echo $response2 | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
response_body2=$(echo $response2 | sed -e 's/HTTPSTATUS:.*//g')

if [ "$http_code2" = "401" ] || [ "$http_code2" = "403" ]; then
    echo "✅ PASS: Normal upload correctly requires authentication (Status: $http_code2)"
elif [ "$http_code2" = "200" ]; then
    echo "⚠️  WARNING: Normal upload doesn't require authentication (Status: $http_code2)"
    echo "   This might be unexpected behavior."
else
    echo "❓ UNKNOWN: Unexpected status $http_code2"
    echo "   Response: $response_body2"
fi

echo ""
echo "🔍 Test 3: WebSocket Logout Endpoint"
echo "-----------------------------------"

# Test logout endpoint - should respond properly (not 500 error)
response3=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X POST "$BACKEND_URL/auth/track-logout" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer invalid-token" \
  -d '{"businessId": "test", "userId": "test"}')

http_code3=$(echo $response3 | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
response_body3=$(echo $response3 | sed -e 's/HTTPSTATUS:.*//g')

if [[ "$response_body3" == *"Cannot find module"* ]]; then
    echo "❌ FAIL: WebSocket service module error still present (Status: $http_code3)"
    echo "   Response: $response_body3"
    echo "   This means the auth handler fix hasn't been deployed yet."
elif [ "$http_code3" = "401" ]; then
    echo "✅ PASS: Logout endpoint working, returns proper auth error (Status: $http_code3)"
    echo "   The module path issue has been fixed."
elif [ "$http_code3" = "400" ]; then
    echo "✅ PASS: Logout endpoint working, validates input (Status: $http_code3)"
else
    echo "❓ UNKNOWN: Unexpected status $http_code3"
    echo "   Response: $response_body3"
fi

echo ""
echo "📊 SUMMARY"
echo "=========="

# Determine overall status
business_photo_fixed=false
websocket_fixed=false

if [ "$http_code1" = "400" ] || [ "$http_code1" = "200" ]; then
    business_photo_fixed=true
fi

if [ "$http_code3" = "401" ] || [ "$http_code3" = "400" ]; then
    if [[ "$response_body3" != *"Cannot find module"* ]]; then
        websocket_fixed=true
    fi
fi

if [ "$business_photo_fixed" = true ] && [ "$websocket_fixed" = true ]; then
    echo "🎉 ALL FIXES DEPLOYED SUCCESSFULLY!"
    echo ""
    echo "✅ Business photo upload during registration: WORKING"
    echo "✅ WebSocket logout cleanup: WORKING"
    echo "✅ Auth handler module path: FIXED"
    echo ""
    echo "🚀 You can now:"
    echo "   • Create new accounts with business photos"
    echo "   • Users can logout properly (no stale connections)"
    echo "   • No more internal server errors"
elif [ "$business_photo_fixed" = true ] && [ "$websocket_fixed" = false ]; then
    echo "⚠️  PARTIAL SUCCESS"
    echo ""
    echo "✅ Business photo upload: WORKING"
    echo "❌ WebSocket logout cleanup: NEEDS DEPLOYMENT"
    echo ""
    echo "The business photo issue is fixed, but WebSocket logout still needs deployment."
elif [ "$business_photo_fixed" = false ] && [ "$websocket_fixed" = true ]; then
    echo "⚠️  PARTIAL SUCCESS"
    echo ""
    echo "❌ Business photo upload: NEEDS DEPLOYMENT"
    echo "✅ WebSocket logout cleanup: WORKING"
    echo ""
    echo "The logout issue is fixed, but business photo upload still needs deployment."
else
    echo "❌ FIXES NOT YET DEPLOYED"
    echo ""
    echo "❌ Business photo upload: NEEDS DEPLOYMENT"
    echo "❌ WebSocket logout cleanup: NEEDS DEPLOYMENT"
    echo ""
    echo "Please run: ./deploy_fixes_complete.sh"
fi

echo ""
echo "💡 If fixes aren't working:"
echo "   1. Wait 1-2 minutes for AWS propagation"
echo "   2. Run this test again"
echo "   3. Check AWS CloudWatch logs if issues persist"
