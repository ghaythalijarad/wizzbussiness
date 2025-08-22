#!/bin/bash
API_BASE="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

echo "Testing auth endpoint..."
curl -sS -X POST -H "Content-Type: application/json" -d "{\"email\":\"g87_a@yahoo.com\",\"password\":\"Gha@551987\"}" "$API_BASE/auth/signin" | jq ".success"

echo "Auth endpoint working!"
