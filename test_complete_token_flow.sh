#!/bin/bash

echo "🔍 TESTING COMPLETE TOKEN STORAGE AND USAGE FLOW"
echo "================================================"

echo ""
echo "💻 BACKEND TEST - Testing what tokens we're getting from signin:"

# Test signing in via API to see what tokens we get
curl -X POST "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/signin" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ghaythmobile@gmail.com",
    "password": "ghayth99"
  }' | jq '.'

echo ""
echo "📱 FLUTTER APP TEST - Please test in the running app:"
echo "1. Sign out completely"
echo "2. Sign in with your credentials"
echo "3. Check console for token storage messages:"
echo "   - 💾 Storing access token (length: X)"
echo "   - 💾 Storing ID token (length: X)"
echo "4. Go to Location Settings"
echo "5. Try to save location settings"
echo "6. Check console for authorization token usage:"
echo "   - 🎫 [TokenManager] Using ID token for authorization"
echo ""
echo "🎯 SUCCESS INDICATORS:"
echo "✅ Both access and ID tokens stored during sign-in"
echo "✅ ID token used for API Gateway authorization"
echo "✅ Location settings save successfully"
