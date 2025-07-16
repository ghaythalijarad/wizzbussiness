#!/bin/bash

# 🚀 Flutter App Quick Start Script
# This script starts the Flutter app with the correct configuration

echo "🎯 Starting Flutter Order Receiver App"
echo "======================================"

# Navigate to frontend directory
cd "$(dirname "$0")/frontend" || exit 1

echo "📱 Target Device: iPhone 16 Pro Simulator"
echo "🔐 Authentication: AWS Cognito"
echo "🌐 Environment: Development"
echo ""

# Start Flutter with correct configuration
flutter run \
  -d "03184DD9-8876-479E-8087-548185C2F3A4" \
  --dart-define=AUTH_MODE=cognito \
  --dart-define=COGNITO_USER_POOL_ID=us-east-1_bDqnKdrqo \
  --dart-define=COGNITO_APP_CLIENT_ID=6n752vrmqmbss6nmlg6be2nn9a \
  --dart-define=REGION=us-east-1 \
  --dart-define=API_BASE_URL=https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev

echo ""
echo "✅ App started successfully!"
echo "🔑 Test Credentials:"
echo "   Email: g87_a@outlook.com"
echo "   Password: Password123!"
