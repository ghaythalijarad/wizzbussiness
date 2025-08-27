#!/bin/bash

# Test Flutter App Logout Flow End-to-End
# This script will test the complete logout flow through the Flutter app

echo "🧪 Testing Flutter App Logout Flow End-to-End"
echo "=============================================="
echo ""

# Step 1: Launch Flutter app in iOS Simulator
echo "1️⃣ Launching Flutter app in iOS Simulator..."
echo "   This will start the app in development mode"
echo "   You can then manually test the logout flow"
echo ""

# Check if Simulator is already running
if pgrep -x "Simulator" > /dev/null; then
    echo "   ✅ iOS Simulator is already running"
else
    echo "   🚀 Starting iOS Simulator..."
    open -a Simulator
    sleep 5
fi

# Start Flutter app
echo "   🚀 Starting Flutter app..."
cd frontend

# Run Flutter with enhanced logging
flutter run --verbose \
    --dart-define=ENVIRONMENT=development \
    --dart-define=API_URL=https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev \
    --dart-define=AUTH_MODE=cognito \
    --dart-define=COGNITO_USER_POOL_ID=us-east-1_PHPkG78b5 \
    --dart-define=APP_CLIENT_ID=1tl9g7nk2k2chtj5fg960fgdth \
    --dart-define=COGNITO_REGION=us-east-1 \
    --dart-define=FEATURE_SET=enhanced &

FLUTTER_PID=$!

echo ""
echo "📱 Flutter app is starting..."
echo "   PID: $FLUTTER_PID"
echo ""
echo "🧪 Manual Testing Instructions:"
echo "==============================="
echo "1. Wait for the app to load completely"
echo "2. Login with a test account (or register if needed)"
echo "3. Navigate to any screen that establishes WebSocket connection"
echo "4. Sign out of the app"
echo "5. Check the console logs for WebSocket cleanup messages"
echo ""
echo "🔍 Look for these log messages:"
echo "   - '📋 Tracking business user logout'"
echo "   - '✅ Business logout tracked successfully'"
echo "   - 'Professional logout tracking processed'"
echo ""
echo "⚠️  If you see errors like 'Error tracking business logout', that indicates"
echo "    the cleanup mechanism might need further investigation."
echo ""
echo "Press Ctrl+C to stop the Flutter app when testing is complete."

# Wait for the Flutter process to finish
wait $FLUTTER_PID

echo ""
echo "🏁 Flutter app has stopped."
