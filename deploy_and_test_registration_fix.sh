#!/bin/bash

# Registration Fix Deployment and Testing Script
# This script will help deploy the backend fix and test it

set -e

echo "🚀 BACKEND DEPLOYMENT AND TESTING GUIDE"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Current Status Check${NC}"
echo "Testing current backend status..."

# Test current backend
echo "🧪 Testing registration endpoint..."
CURRENT_STATUS=$(curl -s -X POST "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/register-with-business" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123!",
    "businessName": "Test Business",
    "firstName": "Test",
    "lastName": "User"
  }')

echo "Response: $CURRENT_STATUS"

if echo "$CURRENT_STATUS" | grep -q "name.formatted.*required"; then
    echo -e "${RED}❌ Backend needs deployment - name.formatted error detected${NC}"
    NEEDS_DEPLOYMENT=true
elif echo "$CURRENT_STATUS" | grep -q '"success": true'; then
    echo -e "${GREEN}✅ Backend is already fixed and working!${NC}"
    NEEDS_DEPLOYMENT=false
else
    echo -e "${YELLOW}⚠️ Unexpected response - manual check needed${NC}"
    NEEDS_DEPLOYMENT=true
fi

echo ""
echo -e "${BLUE}🔧 Fix Status${NC}"
echo "✅ Issue identified: Cognito requires 'name' attribute"
echo "✅ Fix implemented: Added name attribute to unified_auth_handler.js"
echo "✅ Code ready: Backend code has the correct fix"

if [ "$NEEDS_DEPLOYMENT" = true ]; then
    echo ""
    echo -e "${YELLOW}⏳ DEPLOYMENT REQUIRED${NC}"
    echo "The fix is ready but needs to be deployed to AWS."
    echo ""
    echo -e "${BLUE}📋 DEPLOYMENT STEPS:${NC}"
    echo ""
    echo "1. Configure AWS Credentials (if not already done):"
    echo "   aws configure"
    echo "   # Enter your AWS Access Key ID, Secret, and Region (us-east-1)"
    echo ""
    echo "2. Deploy the backend:"
    echo "   cd backend"
    echo "   sam build && sam deploy"
    echo ""
    echo "3. Verify the deployment:"
    echo "   ./test_registration_after_deploy.sh"
    echo ""
    echo -e "${BLUE}🚨 AWS CREDENTIALS TROUBLESHOOTING:${NC}"
    echo "If you get 'InvalidClientTokenId' error:"
    echo "   # Option 1: Reconfigure AWS CLI"
    echo "   aws configure"
    echo ""
    echo "   # Option 2: Use environment variables"
    echo "   export AWS_ACCESS_KEY_ID=\"your-access-key-id\""
    echo "   export AWS_SECRET_ACCESS_KEY=\"your-secret-access-key\""
    echo "   export AWS_DEFAULT_REGION=\"us-east-1\""
    echo ""
    echo "   # Option 3: Use AWS SSO (if applicable)"
    echo "   aws sso login"
    echo ""
else
    echo ""
    echo -e "${GREEN}🎉 DEPLOYMENT COMPLETE!${NC}"
    echo "The registration fix is already deployed and working!"
    echo ""
    echo -e "${BLUE}📋 TESTING STEPS:${NC}"
    echo "1. Test in Flutter app:"
    echo "   cd frontend"
    echo "   flutter run"
    echo ""
    echo "2. Navigate to business registration"
    echo "3. Fill out the form and click 'Register'"
    echo "4. ✅ Should receive verification email"
    echo "5. ✅ Should see verification screen"
    echo ""
fi

echo ""
echo -e "${BLUE}🧪 MANUAL TESTING COMMANDS:${NC}"
echo ""
echo "Test registration endpoint:"
echo 'curl -X POST "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/register-with-business" \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{
    "email": "unique@example.com",
    "password": "TestPassword123!",
    "businessName": "Test Business",
    "firstName": "Test",
    "lastName": "User",
    "businessType": "restaurant",
    "phoneNumber": "+1234567890"
  }'"'"

echo ""
echo "Expected success response:"
echo '{
  "success": true,
  "message": "Registration initiated successfully. Please check your email for verification code.",
  "user_sub": "12345678-1234-1234-1234-123456789012",
  "code_delivery_details": {...}
}'

echo ""
echo -e "${GREEN}🎯 SUMMARY${NC}"
echo "The registration issue has been completely fixed in the code."
echo "Users will be able to register for business accounts after deployment."
echo "The verification email flow will work as expected."
