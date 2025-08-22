#!/bin/bash

# Test products endpoint with authentication
API_BASE="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
EMAIL="g87_a@yahoo.com"
PASSWORD="${PASSWORD:-testpass123}"

echo "=== Testing Products Endpoint with Authentication ==="
echo "API Base: $API_BASE"
echo "Email: $EMAIL"
echo

# Step 1: Login to get tokens
echo "1. Authenticating user..."
SIGNIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/signin" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

echo "Signin Response:"
echo "$SIGNIN_RESPONSE" | jq '.' 2>/dev/null || echo "$SIGNIN_RESPONSE"
echo

# Extract access token
ACCESS_TOKEN=$(echo "$SIGNIN_RESPONSE" | jq -r '.data.tokens.AccessToken // .tokens.AccessToken // empty' 2>/dev/null)
ID_TOKEN=$(echo "$SIGNIN_RESPONSE" | jq -r '.data.tokens.IdToken // .tokens.IdToken // empty' 2>/dev/null)

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
    echo "❌ Failed to get access token"
    echo "Response: $SIGNIN_RESPONSE"
    exit 1
fi

echo "✅ Got access token (${#ACCESS_TOKEN} chars)"
echo "✅ Got ID token (${#ID_TOKEN} chars)"
echo

# Step 2: Test products endpoint with access token
echo "2. Testing /products endpoint with access token..."
PRODUCTS_RESPONSE=$(curl -s -X GET "$API_BASE/products" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json")

echo "Products Response:"
echo "$PRODUCTS_RESPONSE" | jq '.' 2>/dev/null || echo "$PRODUCTS_RESPONSE"
echo

# Step 3: Test products endpoint with ID token
echo "3. Testing /products endpoint with ID token..."
PRODUCTS_ID_RESPONSE=$(curl -s -X GET "$API_BASE/products" \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json")

echo "Products Response (ID Token):"
echo "$PRODUCTS_ID_RESPONSE" | jq '.' 2>/dev/null || echo "$PRODUCTS_ID_RESPONSE"
echo

# Step 4: Test with Authorization header without Bearer prefix
echo "4. Testing /products endpoint without Bearer prefix..."
PRODUCTS_NO_BEARER=$(curl -s -X GET "$API_BASE/products" \
  -H "Authorization: $ACCESS_TOKEN" \
  -H "Content-Type: application/json")

echo "Products Response (No Bearer):"
echo "$PRODUCTS_NO_BEARER" | jq '.' 2>/dev/null || echo "$PRODUCTS_NO_BEARER"
echo

# Step 5: Check token claims
echo "5. Checking token claims..."
echo "Access Token Header:"
echo "$ACCESS_TOKEN" | cut -d'.' -f1 | base64 -d 2>/dev/null | jq '.' || echo "Failed to decode header"
echo
echo "Access Token Payload:"
echo "$ACCESS_TOKEN" | cut -d'.' -f2 | base64 -d 2>/dev/null | jq '.' || echo "Failed to decode payload"
