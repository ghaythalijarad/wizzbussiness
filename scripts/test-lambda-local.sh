#!/bin/bash

# Local testing script for Lambda functions
# Usage: ./test-lambda-local.sh

set -e

echo "🧪 Testing Lambda functions locally..."

# Navigate to backend directory
cd "$(dirname "$0")/../backend"

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    echo "❌ SAM CLI not found. Please install it first:"
    echo "   brew install aws-sam-cli"
    exit 1
fi

# Build the application
echo "🏗️ Building SAM application for local testing..."
sam build --template template.yaml

# Start local API
echo "🌐 Starting local API Gateway..."
echo "   API will be available at: http://127.0.0.1:3000"
echo "   Press Ctrl+C to stop"
echo ""

# Create a background process to test the API once it's ready
(
    echo "⏳ Waiting for API to be ready..."
    sleep 5
    
    echo "🧪 Running API tests..."
    
    # Test root endpoint
    echo "  Testing GET /"
    curl -s http://127.0.0.1:3000/ | jq . || echo "❌ Root endpoint failed"
    
    # Test health endpoint
    echo "  Testing GET /health"
    curl -s http://127.0.0.1:3000/health | jq . || echo "❌ Health endpoint failed"
    
    # Test auth health endpoint
    echo "  Testing GET /auth/health"
    curl -s http://127.0.0.1:3000/auth/health | jq . || echo "❌ Auth health endpoint failed"
    
    # Test business registration with invalid data
    echo "  Testing POST /auth/register-business (invalid data)"
    curl -s -X POST http://127.0.0.1:3000/auth/register-business \
        -H "Content-Type: application/json" \
        -d '{"cognito_user_id":"","email":"invalid"}' | jq . || echo "❌ Business registration endpoint failed"
    
    # Test business registration with valid data
    echo "  Testing POST /auth/register-business (valid data)"
    curl -s -X POST http://127.0.0.1:3000/auth/register-business \
        -H "Content-Type: application/json" \
        -d '{
            "cognito_user_id": "test-user-123",
            "email": "test@example.com",
            "business_name": "Test Restaurant",
            "business_type": "restaurant",
            "owner_name": "John Doe",
            "phone_number": "+1234567890",
            "address": {
                "street": "123 Main St",
                "city": "Test City",
                "zipcode": "12345"
            }
        }' | jq . || echo "❌ Business registration with valid data failed"
    
    echo ""
    echo "✅ Basic API tests completed"
    echo "🌐 API is running at http://127.0.0.1:3000"
    echo "📚 Available endpoints:"
    echo "   GET  http://127.0.0.1:3000/"
    echo "   GET  http://127.0.0.1:3000/health"
    echo "   GET  http://127.0.0.1:3000/health/detailed"
    echo "   GET  http://127.0.0.1:3000/auth/health"
    echo "   POST http://127.0.0.1:3000/auth/register-business"
    echo ""
    echo "💡 Test with curl or your frontend application"
    echo "🛑 Press Ctrl+C to stop the local API"
    
) &

# Start the local API (this will block)
export DYNAMODB_TABLE_NAME="order-receiver-businesses-local"
sam local start-api --host 127.0.0.1 --port 3000
