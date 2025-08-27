#!/bin/zsh

echo "🔧 Flutter iOS Launch Troubleshooter"
echo "=================================="

# Set working directory
cd /Users/ghaythallaheebi/order-receiver-app-2/frontend

echo "📱 Step 1: Opening iOS Simulator..."
open -a Simulator
sleep 5

echo "🔍 Step 2: Checking Flutter setup..."
flutter doctor --version

echo "📋 Step 3: Listing available devices..."
flutter devices

echo "🚀 Step 4: Attempting to launch on any available iOS device..."
flutter run --verbose \
  --dart-define=ENVIRONMENT=development \
  --dart-define=API_URL=https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev \
  --dart-define=AUTH_MODE=cognito \
  --dart-define=COGNITO_USER_POOL_ID=us-east-1_PHPkG78b5 \
  --dart-define=APP_CLIENT_ID=1tl9g7nk2k2chtj5fg960fgdth \
  --dart-define=COGNITO_REGION=us-east-1 \
  --dart-define=FEATURE_SET=enhanced

echo "✅ Launch attempt completed!"
