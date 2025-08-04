#!/bin/bash

# Flutter App Real-time Notification Test Script
# This script helps test the Flutter app's real-time notification functionality

echo "📱 Flutter App Real-time Notification Test"
echo "=========================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

# Navigate to frontend directory
FRONTEND_DIR="/Users/ghaythallaheebi/order-receiver-app-2/frontend"

if [ ! -d "$FRONTEND_DIR" ]; then
    echo "❌ Frontend directory not found: $FRONTEND_DIR"
    exit 1
fi

cd "$FRONTEND_DIR"

echo "📍 Working directory: $(pwd)"
echo ""

# Check Flutter project
echo "🔍 Checking Flutter project..."
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Not a Flutter project (pubspec.yaml not found)"
    exit 1
fi

echo "✅ Flutter project found"

# Clean and get dependencies
echo ""
echo "🧹 Cleaning Flutter project..."
flutter clean

echo ""
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Check for any issues
echo ""
echo "🔍 Analyzing Flutter project..."
flutter analyze --no-fatal-infos

# Build the app (this will catch any compilation errors)
echo ""
echo "🔨 Building Flutter app..."
flutter build apk --debug --verbose

if [ $? -eq 0 ]; then
    echo "✅ Flutter app built successfully"
else
    echo "❌ Flutter app build failed"
    exit 1
fi

echo ""
echo "📋 Flutter Test Instructions:"
echo "=============================="
echo ""
echo "1. 🚀 Run the backend real-time test first:"
echo "   cd /Users/ghaythallaheebi/order-receiver-app-2"
echo "   node test_realtime_notifications.js business_123"
echo ""
echo "2. 📱 Then run the Flutter app on a device/emulator:"
echo "   cd $FRONTEND_DIR"
echo "   flutter run"
echo ""
echo "3. 🔐 Login to the Flutter app with test credentials"
echo ""
echo "4. 📋 Navigate to the Orders page"
echo ""
echo "5. 🧪 Send a test order by running the backend test again:"
echo "   node test_realtime_notifications.js business_123"
echo ""
echo "6. ✅ Expected behavior:"
echo "   - New order should appear instantly on Orders page"
echo "   - SnackBar notification should show: '🆕 New order: order_id'"
echo "   - Red badge should appear on notification bell"
echo "   - No manual refresh/navigation required"
echo ""
echo "🔧 Troubleshooting:"
echo "==================="
echo ""
echo "If notifications don't work:"
echo ""
echo "1. Check WebSocket connection in Flutter logs:"
echo "   Look for: 'WebSocket connected', 'Connection established'"
echo ""
echo "2. Check real-time service initialization:"
echo "   Look for: 'RealtimeOrderService initialized'"
echo ""
echo "3. Check notification reception:"
echo "   Look for: 'New order received via WebSocket'"
echo ""
echo "4. Verify backend deployment:"
echo "   cd backend && serverless deploy"
echo ""
echo "5. Check DynamoDB tables:"
echo "   - order-receiver-orders-dev (orders)"
echo "   - order-receiver-merchant-endpoints-dev (connections)"
echo ""
echo "6. Test WebSocket endpoint manually:"
echo "   wscat -c 'wss://uhb1o9jggg.execute-api.us-east-1.amazonaws.com/dev?merchantId=business_123'"
echo ""
echo "🎯 Success Criteria:"
echo "==================="
echo ""
echo "✅ Real-time notifications working if:"
echo "   1. WebSocket connects successfully"
echo "   2. New orders appear immediately without refresh"
echo "   3. SnackBar notifications show"
echo "   4. Visual badge indicators appear"
echo "   5. No delays or manual navigation required"
echo ""
echo "🔗 Useful Commands:"
echo "=================="
echo ""
echo "# Check Flutter logs"
echo "flutter logs"
echo ""
echo "# Run on specific device"
echo "flutter devices"
echo "flutter run -d <device_id>"
echo ""
echo "# Hot reload during testing"
echo "# Press 'r' in Flutter console"
echo ""
echo "# Debug network connections"
echo "# Add --verbose flag to flutter run"
echo ""

echo "🏁 Flutter app is ready for real-time notification testing!"
echo ""
echo "Next: Run 'flutter run' and follow the test instructions above."
