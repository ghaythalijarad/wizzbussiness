#!/bin/bash

echo "🔍 Testing Token and Business Lookup"
echo "===================================="

API_BASE="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
EMAIL="G87_a@yahoo.com"
PASSWORD="Password123!"

echo "📧 Getting access token for: $EMAIL"

# Test signin endpoint
SIGNIN_RESPONSE=$(curl -s -X POST \
  "$API_BASE/auth/signin" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'"$EMAIL"'",
    "password": "'"$PASSWORD"'"
  }')

ACCESS_TOKEN=$(echo "$SIGNIN_RESPONSE" | grep -o '"AccessToken":"[^"]*"' | cut -d'"' -f4)

if [ -n "$ACCESS_TOKEN" ]; then
    echo "✅ Access Token obtained (first 20 chars): ${ACCESS_TOKEN:0:20}..."
    
    echo ""
    echo "🔍 Testing Cognito token validation..."
    
    # Let's test if we can decode the token manually
    aws sts get-caller-identity --profile wizz-merchants-dev
    
    echo ""
    echo "🛍️ Testing products endpoint with detailed error..."
    
    PRODUCTS_RESPONSE=$(curl -v -X GET \
      "$API_BASE/products" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ACCESS_TOKEN" 2>&1)
    
    echo "$PRODUCTS_RESPONSE"
else
    echo "❌ Failed to get access token"
fi
