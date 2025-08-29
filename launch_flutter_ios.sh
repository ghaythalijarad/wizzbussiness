#!/bin/bash

echo "🚀 Launching Flutter App on iOS Simulator..."

# Open iOS Simulator
echo "📱 Starting iOS Simulator..."
open -a Simulator

# Wait for simulator to start
sleep 3

# Boot the specific iPhone 16 Plus device
echo "🔄 Booting iPhone 16 Plus simulator..."
xcrun simctl boot A3DDA783-158C-4D71-B5D6-E617966BE41D || echo "Device may already be booted"

# Wait for device to boot
sleep 2

# Change to frontend directory
cd /Users/ghaythallaheebi/order-receiver-app-2/frontend

# Check Flutter devices
echo "📋 Checking available devices..."
flutter devices

# Launch Flutter app with all environment variables
echo "🚀 Launching Flutter app..."
flutter run -d A3DDA783-158C-4D71-B5D6-E617966BE41D \
  --dart-define=ENVIRONMENT=development \
  --dart-define=API_URL=https://m90p0zj1g1.execute-api.us-east-1.amazonaws.com/dev \
  --dart-define=AUTH_MODE=cognito \
  --dart-define=COGNITO_USER_POOL_ID=us-east-1_PHPkG78b5 \
  --dart-define=APP_CLIENT_ID=1tl9g7nk2k2chtj5fg960fgdth \
  --dart-define=COGNITO_REGION=us-east-1 \
  --dart-define=FEATURE_SET=enhanced

echo "✅ Flutter app launched!"
