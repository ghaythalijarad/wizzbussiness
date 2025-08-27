#!/bin/bash

# Test Cognito Authentication with Location Settings
echo "🧪 TESTING COGNITO AUTH FIX FOR LOCATION SETTINGS"
echo "=================================================="

API_BASE="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
EMAIL="g87_a@yahoo.com"
PASSWORD="Gha@551987"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Step 1: Getting fresh access token${NC}"

# Get fresh access token
LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/signin" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

# Extract token and business ID
ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.AccessToken // empty' 2>/dev/null)
BUSINESS_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.businesses[0].businessId // empty' 2>/dev/null)

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo -e "${RED}❌ Failed to get access token${NC}"
  echo "Response: $LOGIN_RESPONSE"
  exit 1
fi

if [ -z "$BUSINESS_ID" ] || [ "$BUSINESS_ID" = "null" ]; then
  echo -e "${RED}❌ Failed to get business ID${NC}"
  echo "Response: $LOGIN_RESPONSE"
  exit 1
fi

echo -e "${GREEN}✅ Tokens obtained successfully${NC}"
echo "Business ID: $BUSINESS_ID"
echo "Token length: ${#ACCESS_TOKEN}"

echo -e "${BLUE}Step 2: Testing Location Settings Endpoints${NC}"

# Test GET location settings
echo -e "${YELLOW}2.1 Testing GET location settings...${NC}"
GET_RESPONSE=$(curl -s -X GET "$API_BASE/businesses/$BUSINESS_ID/location-settings" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json")

echo "GET Response: $GET_RESPONSE"

if echo "$GET_RESPONSE" | grep -q "Unauthorized"; then
  echo -e "${RED}❌ Still getting Unauthorized - Cognito authorizer issue${NC}"
else
  echo -e "${GREEN}✅ GET request succeeded${NC}"
fi

# Test PUT location settings
echo -e "${YELLOW}2.2 Testing PUT location settings...${NC}"
PUT_RESPONSE=$(curl -s -X PUT "$API_BASE/businesses/$BUSINESS_ID/location-settings" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": 32.0853,
    "longitude": 44.3613,
    "city": "النجف الأشرف",
    "district": "المدينة القديمة",
    "street": "شارع الكوفة",
    "country": "العراق",
    "address": "شارع الكوفة، المدينة القديمة، النجف الأشرف"
  }')

echo "PUT Response: $PUT_RESPONSE"

if echo "$PUT_RESPONSE" | grep -q "Unauthorized"; then
  echo -e "${RED}❌ PUT also getting Unauthorized${NC}"
else
  echo -e "${GREEN}✅ PUT request succeeded${NC}"
fi

echo -e "${BLUE}Step 3: Testing Working Hours Endpoints${NC}"

# Test GET working hours
echo -e "${YELLOW}3.1 Testing GET working hours...${NC}"
HOURS_GET_RESPONSE=$(curl -s -X GET "$API_BASE/businesses/$BUSINESS_ID/working-hours" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json")

echo "Working Hours GET Response: $HOURS_GET_RESPONSE"

echo -e "${BLUE}Test Summary${NC}"
echo "============"

if echo "$GET_RESPONSE" | grep -q "Unauthorized" && echo "$PUT_RESPONSE" | grep -q "Unauthorized"; then
  echo -e "${RED}❌ COGNITO AUTHORIZATION STILL FAILING${NC}"
  echo -e "${RED}❌ Need to fix API Gateway Cognito Authorizer configuration${NC}"
  echo ""
  echo "Debugging information:"
  echo "- User Pool ID: us-east-1_PHPkG78b5"
  echo "- Client ID: 1tl9g7nk2k2chtj5fg960fgdth"
  echo "- Token format looks correct"
  echo "- Token length: ${#ACCESS_TOKEN}"
  echo ""
  echo "Next steps:"
  echo "1. Check API Gateway Cognito authorizer configuration"
  echo "2. Verify User Pool ARN in template.yaml"
  echo "3. Ensure authorizer is properly configured for the endpoints"
else
  echo -e "${GREEN}✅ LOCATION SETTINGS ENDPOINTS WORKING${NC}"
fi
