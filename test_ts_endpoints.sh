#!/bin/bash

echo "🧪 Testing TypeScript endpoints..."

API_BASE="https://e7xk96gfm9.execute-api.us-east-1.amazonaws.com/Prod"

echo ""
echo "1. Testing public categories endpoint..."
curl -s -w "Status: %{http_code}\n" "${API_BASE}/categories-ts/business-type/restaurant" | head -20

echo ""
echo "2. Testing signin endpoint..."
curl -s -w "Status: %{http_code}\n" -X POST "${API_BASE}/auth-ts/signin" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass"}' | head -20

echo ""
echo "3. Testing products endpoint (should require auth)..."
curl -s -w "Status: %{http_code}\n" "${API_BASE}/products-ts" | head -10

echo ""
echo "✅ Endpoint tests completed!"
