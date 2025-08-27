#!/bin/bash

echo "🔄 Restarting Flutter app with updated backend..."

# Kill any existing Flutter processes
pkill -f "flutter run" 2>/dev/null || true

# Wait a moment for processes to terminate
sleep 2

# Navigate to frontend directory
cd /Users/ghaythallaheebi/order-receiver-app-2/frontend

# Start Flutter with all environment variables
flutter run -d A3DDA783-158C-4D71-B5D6-E617966BE41D \
  --dart-define=ENVIRONMENT=development \
  --dart-define=API_URL=https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev \
  --dart-define=AUTH_MODE=cognito \
  --dart-define=COGNITO_USER_POOL_ID=us-east-1_PHPkG78b5 \
  --dart-define=APP_CLIENT_ID=1tl9g7nk2k2chtj5fg960fgdth \
  --dart-define=COGNITO_REGION=us-east-1 \
  --dart-define=FEATURE_SET=enhanced

echo "✅ Flutter app restarted!"
