#!/bin/bash

echo "🧪 TESTING TOKEN CORRUPTION ISSUE"
echo "================================="

# Test the exact error pattern we're seeing
echo "Testing Authorization header with corrupted token..."

# This is the pattern from the error: 'VluqHyE7IrQ\n.'=rrd4knvhfHZqyU220i15Ad+PXYIkR5Z0
# Notice the \n and the = which breaks the "key=value pair" parsing

# Create a test with curl to see the exact error
echo ""
echo "1. Testing with corrupted token (has newline)..."
curl -v -X POST "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/products" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer VluqHyE7IrQ
.rrd4knvhfHZqyU220i15Ad+PXYIkR5Z0" \
  -d '{"name":"test","description":"test","price":10,"categoryId":"test"}' \
  2>&1 | grep -i "invalid\|error" || echo "No obvious error in curl output"

echo ""
echo "2. Testing with sanitized token (no newline)..."
curl -v -X POST "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/products" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer VluqHyE7IrQrrd4knvhfHZqyU220i15Ad+PXYIkR5Z0" \
  -d '{"name":"test","description":"test","price":10,"categoryId":"test"}' \
  2>&1 | grep -i "invalid\|error" || echo "No obvious error in curl output"

echo ""
echo "✅ Test completed - check the output above for any 'Invalid key=value pair' errors"
