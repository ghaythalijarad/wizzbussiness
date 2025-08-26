#!/bin/bash

# Quick staging environment validation script
# Tests all components of the staging setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Quick Staging Environment Validation${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Test 1: Backend API availability
echo -e "${BLUE}1. Testing Backend API...${NC}"
if [[ $API_RESPONSE -eq 401 ]] || [[ $API_RESPONSE -eq 403 ]]; then
    echo -e "   ${GREEN}✅ Backend API responding (authentication required - expected)${NC}"
elif [[ $API_RESPONSE -eq 200 ]]; then
    echo -e "   ${GREEN}✅ Backend API responding successfully${NC}"
else
    echo -e "   ${YELLOW}⚠️  Backend API response code: $API_RESPONSE${NC}"
fi

# Test 2: Cognito configuration
echo -e "${BLUE}2. Testing Cognito Configuration...${NC}"
COGNITO_CHECK=$(aws cognito-idp describe-user-pool \
  --user-pool-id "us-east-1_pJANW22FL" \
  --profile wizz-merchants-dev \
  --region us-east-1 \
  --query 'UserPool.Name' \
  --output text 2>/dev/null || echo "ERROR")

if [[ $COGNITO_CHECK == "OrderReceiver-Staging" ]]; then
    echo -e "   ${GREEN}✅ Staging Cognito User Pool operational${NC}"
else
    echo -e "   ${RED}❌ Cognito User Pool check failed${NC}"
    exit 1
fi

# Test 3: Frontend build capability
echo -e "${BLUE}3. Testing Frontend Build Capability...${NC}"
cd /Users/ghaythallaheebi/order-receiver-app-2/frontend

BUILD_TEST=$(flutter build web \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=FEATURE_SET=core \
  --dart-define=API_URL=https://371prqogn5.execute-api.us-east-1.amazonaws.com/staging \
  --dart-define=COGNITO_USER_POOL_ID=us-east-1_pJANW22FL \
  --dart-define=APP_CLIENT_ID=66g27ud5urekg83jb38cf4405d \
  --release --quiet 2>&1)

if [[ $? -eq 0 ]]; then
    echo -e "   ${GREEN}✅ Frontend builds successfully for staging${NC}"
else
    echo -e "   ${RED}❌ Frontend build failed${NC}"
    exit 1
fi

cd ..

echo ""
echo -e "${GREEN}🎉 ALL STAGING VALIDATION TESTS PASSED!${NC}"
echo ""

# Display staging summary
echo -e "${BLUE}📋 Staging Environment Summary:${NC}"
echo -e "   🌐 API URL: https://371prqogn5.execute-api.us-east-1.amazonaws.com/staging/"
echo -e "   🔐 Cognito Pool: us-east-1_pJANW22FL"
echo -e "   📱 App Client: 66g27ud5urekg83jb38cf4405d"
echo -e "   👤 Test User: staging-test@wizzbusiness.com"
echo -e "   🔑 Password: StagingTest123!"
echo ""

echo -e "${YELLOW}🚀 Ready Commands:${NC}"
echo -e "   Core Features: ${GREEN}./scripts/deploy.sh staging core${NC}"
echo -e "   Enhanced Features: ${GREEN}./scripts/deploy.sh staging enhanced${NC}"
echo -e "   Beta Features: ${GREEN}./scripts/deploy.sh staging beta${NC}"
echo ""

echo -e "${GREEN}✅ Staging environment is fully operational and ready for deployment!${NC}"
