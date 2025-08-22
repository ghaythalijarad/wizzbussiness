#!/bin/bash

# Test script to verify authentication fix
echo "🧪 TESTING AUTHENTICATION FIX"
echo "=============================="
echo ""

BASE_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
TEST_EMAIL="ghaythal.laheebi@gmail.com"
TEST_PASSWORD="TestPassword123!"

echo "1. Signing in..."

# Step 1: Sign in to get tokens
SIGNIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/signin" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

echo "📡 Sign-in response: $SIGNIN_RESPONSE"

# Extract tokens using jq (if available) or basic parsing
if command -v jq &> /dev/null; then
    SUCCESS=$(echo "$SIGNIN_RESPONSE" | jq -r '.success // false')
    if [ "$SUCCESS" = "true" ]; then
        ACCESS_TOKEN=$(echo "$SIGNIN_RESPONSE" | jq -r '.data.AccessToken // empty')
        ID_TOKEN=$(echo "$SIGNIN_RESPONSE" | jq -r '.data.IdToken // empty')
        
        echo "✅ Sign-in successful"
        echo "📏 Access token length: ${#ACCESS_TOKEN}"
        echo "📏 ID token length: ${#ID_TOKEN}"
        echo "🔑 ID token preview: ${ID_TOKEN:0:50}..."
        
        echo ""
        echo "2. Testing API calls with tokens..."
        
        # Test products endpoint with ID token
        echo "📡 Testing products endpoint with ID token..."
        PRODUCTS_RESPONSE=$(curl -s -X GET "$BASE_URL/products" \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer $ID_TOKEN")
        
        echo "📄 Products response: $PRODUCTS_RESPONSE"
        
        # Check if response contains success or products
        if [[ "$PRODUCTS_RESPONSE" == *"products"* ]] || [[ "$PRODUCTS_RESPONSE" == *"success"* ]]; then
            echo "✅ Products API call successful with ID token"
        else
            echo "❌ Products API call failed with ID token"
            
            echo "   Trying with access token..."
            FALLBACK_RESPONSE=$(curl -s -X GET "$BASE_URL/products" \
              -H "Content-Type: application/json" \
              -H "Authorization: Bearer $ACCESS_TOKEN")
            
            echo "📄 Fallback response: $FALLBACK_RESPONSE"
            
            if [[ "$FALLBACK_RESPONSE" == *"products"* ]] || [[ "$FALLBACK_RESPONSE" == *"success"* ]]; then
                echo "✅ Products API call successful with access token"
            else
                echo "❌ Both token types failed"
            fi
        fi
        
        echo ""
        echo "3. Testing user businesses endpoint..."
        
        # Test user businesses
        BUSINESSES_RESPONSE=$(curl -s -X GET "$BASE_URL/auth/user-businesses" \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer $ID_TOKEN")
        
        echo "📄 User businesses response: $BUSINESSES_RESPONSE"
        
        if [[ "$BUSINESSES_RESPONSE" == *"businesses"* ]] && [[ "$BUSINESSES_RESPONSE" == *"success"* ]]; then
            echo "✅ User businesses endpoint working"
            
            # Extract business ID for merchant orders test
            BUSINESS_ID=$(echo "$BUSINESSES_RESPONSE" | jq -r '.businesses[0].businessId // empty' 2>/dev/null)
            
            if [ -n "$BUSINESS_ID" ] && [ "$BUSINESS_ID" != "null" ]; then
                echo "🏢 Testing merchant orders with business ID: $BUSINESS_ID"
                
                ORDERS_RESPONSE=$(curl -s -X GET "$BASE_URL/merchant/orders/$BUSINESS_ID" \
                  -H "Content-Type: application/json" \
                  -H "Authorization: Bearer $ID_TOKEN")
                
                echo "📄 Merchant orders response: $ORDERS_RESPONSE"
                
                if [[ "$ORDERS_RESPONSE" == *"success"* ]] || [[ "$ORDERS_RESPONSE" == *"orders"* ]]; then
                    echo "✅ Merchant orders endpoint working"
                else
                    echo "❌ Merchant orders endpoint failed"
                fi
            else
                echo "⚠️ No business ID found, skipping merchant orders test"
            fi
        else
            echo "❌ User businesses endpoint failed"
        fi
        
    else
        echo "❌ Sign-in failed"
        echo "📄 Response: $SIGNIN_RESPONSE"
    fi
else
    echo "⚠️ jq not available, basic parsing only"
    if [[ "$SIGNIN_RESPONSE" == *"success\":true"* ]]; then
        echo "✅ Sign-in appears successful (basic check)"
    else
        echo "❌ Sign-in appears to have failed"
        echo "📄 Response: $SIGNIN_RESPONSE"
    fi
fi

echo ""
echo "🎉 Authentication fix test completed!"
