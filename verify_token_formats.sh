#!/bin/bash

echo "🔍 TOKEN FORMAT VERIFICATION - FINAL CHECK"
echo "=========================================="

echo "Testing tokens from our signin endpoint..."

# Get tokens from signin
response=$(curl -s -X POST "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/signin" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ghaythmobile@gmail.com", 
    "password": "ghayth99"
  }')

# Check if successful
if echo "$response" | jq -e '.success' > /dev/null 2>&1; then
    echo "✅ Sign-in successful"
    
    # Extract tokens
    access_token=$(echo "$response" | jq -r '.data.AccessToken')
    id_token=$(echo "$response" | jq -r '.data.IdToken')
    
    echo ""
    echo "🔑 ACCESS TOKEN ANALYSIS:"
    echo "Length: ${#access_token}"
    
    # Decode the payload (second part) of the JWT
    access_payload=$(echo "$access_token" | cut -d'.' -f2)
    # Add padding if needed
    access_payload="${access_payload}$(printf '%*s' $(((4 - ${#access_payload} % 4) % 4)) | tr ' ' '=')"
    access_decoded=$(echo "$access_payload" | base64 -d 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "Access token decoded successfully"
        echo "Has 'aud' field: $(echo "$access_decoded" | jq -r 'has("aud")')"
        echo "Audience value: $(echo "$access_decoded" | jq -r '.aud // "NOT_FOUND"')"
        echo "Token use: $(echo "$access_decoded" | jq -r '.token_use // "NOT_FOUND"')"
    else
        echo "❌ Failed to decode access token"
    fi
    
    echo ""
    echo "🎫 ID TOKEN ANALYSIS:"
    echo "Length: ${#id_token}"
    
    # Decode the payload (second part) of the JWT
    id_payload=$(echo "$id_token" | cut -d'.' -f2)
    # Add padding if needed
    id_payload="${id_payload}$(printf '%*s' $(((4 - ${#id_payload} % 4) % 4)) | tr ' ' '=')"
    id_decoded=$(echo "$id_payload" | base64 -d 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "ID token decoded successfully"
        echo "Has 'aud' field: $(echo "$id_decoded" | jq -r 'has("aud")')"
        echo "Audience value: $(echo "$id_decoded" | jq -r '.aud // "NOT_FOUND"')"
        echo "Token use: $(echo "$id_decoded" | jq -r '.token_use // "NOT_FOUND"')"
    else
        echo "❌ Failed to decode ID token"
    fi
    
    echo ""
    echo "🎯 CONCLUSION:"
    if echo "$id_decoded" | jq -e 'has("aud")' > /dev/null 2>&1; then
        echo "✅ ID token contains 'aud' field - perfect for API Gateway!"
        echo "✅ Our fix should work: use ID token instead of access token"
    else
        echo "❌ ID token also missing 'aud' field - need different approach"
    fi
    
else
    echo "❌ Sign-in failed"
    echo "Response: $response"
fi
