#!/bin/bash

# Simple staging test server
# Hosts the Flutter web build locally for testing

echo "🚀 Starting Staging Test Server"
echo "================================"

cd /Users/ghaythallaheebi/order-receiver-app-2/frontend

# Check if build exists
if [[ ! -d "build/web" ]]; then
    echo "📦 Building staging frontend..."
    flutter build web \
      --dart-define=ENVIRONMENT=staging \
      --dart-define=FEATURE_SET=core \
      --dart-define=API_URL=https://371prqogn5.execute-api.us-east-1.amazonaws.com/staging \
      --dart-define=COGNITO_USER_POOL_ID=us-east-1_pJANW22FL \
      --dart-define=APP_CLIENT_ID=66g27ud5urekg83jb38cf4405d \
      --release
fi

echo ""
echo "🌐 Starting local server for staging app..."
echo ""
echo "📋 Staging Configuration:"
echo "   • Environment: staging"
echo "   • API URL: https://371prqogn5.execute-api.us-east-1.amazonaws.com/staging"
echo "   • Cognito Pool: us-east-1_pJANW22FL"
echo "   • Test User: staging-test@wizzbusiness.com"
echo "   • Password: StagingTest123!"
echo ""
echo "🔗 Access your staging app at: http://localhost:8080"
echo ""
echo "🧪 Test Scenarios:"
echo "1. Login with staging credentials"
echo "2. Test product search functionality"
echo "3. Create and manage orders"
echo "4. Validate dashboard features"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start simple HTTP server
cd build/web
python3 -m http.server 8080
