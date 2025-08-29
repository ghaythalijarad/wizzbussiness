#!/bin/bash

echo "🔄 Force restarting Flutter app..."

# Kill any existing Flutter processes
echo "🛑 Stopping existing Flutter processes..."
pkill -9 -f "flutter" 2>/dev/null || true
sleep 2

# Change to frontend directory
cd /Users/ghaythallaheebi/order-receiver-app-2/frontend

# Clean and get dependencies
echo "🧹 Cleaning Flutter project..."
flutter clean > /dev/null 2>&1
flutter pub get > /dev/null 2>&1

# Check if device is available
echo "📱 Checking iPhone 16 Plus simulator..."
flutter devices | grep A3DDA783-158C-4D71-B5D6-E617966BE41D

# Start Flutter with all environment variables
echo "🚀 Starting Flutter with updated backend configuration..."
flutter run -d A3DDA783-158C-4D71-B5D6-E617966BE41D \
  --dart-define=ENVIRONMENT=development \
  --dart-define=API_URL=https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev \
  --dart-define=AUTH_MODE=cognito \
  --dart-define=COGNITO_USER_POOL_ID=us-east-1_PHPkG78b5 \
  --dart-define=APP_CLIENT_ID=1tl9g7nk2k2chtj5fg960fgdth \
  --dart-define=COGNITO_REGION=us-east-1 \
  --dart-define=FEATURE_SET=enhanced

echo "✅ Flutter app restarted with updated backend!"
