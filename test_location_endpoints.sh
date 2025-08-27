#!/bin/bash

# Test Location Settings Endpoints
echo "🔬 Testing Location Settings Endpoints"
echo "========================================"

API_BASE="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
BUSINESS_ID="test-business-123"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Testing GET ${API_BASE}/businesses/${BUSINESS_ID}/location-settings${NC}"
echo ""

# Test GET endpoint without authorization (should return 401)
echo "1. Testing unauthorized GET request:"
curl -X GET \
  "${API_BASE}/businesses/${BUSINESS_ID}/location-settings" \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\nResponse Time: %{time_total}s\n" \
  -s

echo ""
echo "----------------------------------------"
echo ""

# Test OPTIONS preflight request (CORS)
echo "2. Testing OPTIONS preflight request (CORS):"
curl -X OPTIONS \
  "${API_BASE}/businesses/${BUSINESS_ID}/location-settings" \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: authorization,content-type" \
  -w "\nHTTP Status: %{http_code}\nResponse Time: %{time_total}s\n" \
  -s

echo ""
echo "----------------------------------------"
echo ""

# Test with a dummy JWT token (should return 403 or similar)
echo "3. Testing with invalid JWT token:"
curl -X GET \
  "${API_BASE}/businesses/${BUSINESS_ID}/location-settings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-token-123" \
  -w "\nHTTP Status: %{http_code}\nResponse Time: %{time_total}s\n" \
  -s

echo ""
echo "✅ Basic endpoint connectivity test complete!"
echo ""
echo "Expected results:"
echo "  - Test 1: Should return 401 (Unauthorized) or 403 (Forbidden)"
echo "  - Test 2: Should return 200 with CORS headers"
echo "  - Test 3: Should return 401/403 with invalid token error"
echo ""
echo "If any test returns:"
echo "  - 404: The endpoint is not configured in API Gateway"
echo "  - 502/503: Lambda function error or timeout"
echo "  - Connection refused: API Gateway is not accessible"
