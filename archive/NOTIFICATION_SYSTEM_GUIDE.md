# Notification System Integration Guide

## Overview
This comprehensive notification system enables real-time communication between the customer app (Wizz) and business app, both sharing the same MongoDB database.

## Architecture

### Backend Components
1. **NotificationService** (`/backend/app/services/notification_service.py`)
   - Manages WebSocket connections for real-time notifications
   - Handles notification types: new_order, order_update, payment_received, urgent
   - Stores notification history in MongoDB

2. **Order Management** (`/backend/app/models/order.py` & `/backend/app/controllers/order_controller.py`)
   - Complete order lifecycle tracking
   - Automatic notification triggering on order events
   - Order status updates (pending → confirmed → preparing → ready → delivered)

3. **WebSocket Controller** (`/backend/app/controllers/notification_controller.py`)
   - Real-time WebSocket endpoint: `ws://localhost:8000/notifications/ws/notifications/{business_id}`
   - Notification history API: `GET /notifications/history/{business_id}`
   - Mark as read API: `POST /notifications/mark-read/{business_id}/{notification_id}`

### Frontend Components
1. **NotificationService** (`/frontend/lib/services/notification_service.dart`)
   - WebSocket client for real-time notifications
   - Local notification display using flutter_local_notifications
   - Audio notification sounds using audioplayers
   - Notification history management

2. **NotificationPanel** (`/frontend/lib/widgets/notification_panel.dart`)
   - Complete UI for notification management
   - Real-time connection status
   - Notification statistics and history
   - Interactive notification handling

## Integration Flow

### 1. Customer App Creates Order
```python
# Customer app calls the shared backend
POST /api/orders?business_id={business_id}
{
  "customer_name": "John Doe",
  "items": [...],
  "payment_info": {...}
}
```

### 2. Backend Processes Order
```python
# Order controller automatically:
1. Saves order to MongoDB
2. Generates unique order number
3. Triggers notification to business app
4. Sends WebSocket message to connected business users
```

### 3. Business App Receives Notification
```dart
// Flutter app receives real-time notification
NotificationService().notificationStream.listen((notification) {
  if (notification.isNewOrder) {
    // Show local notification
    // Play notification sound
    // Update UI
  }
});
```

### 4. Business Updates Order Status
```dart
// Business confirms/updates order
ApiService().updateOrderStatus(orderId, "confirmed");
// This triggers notification back to customer app
```

## Setup Instructions

### 1. Backend Setup
```bash
cd backend
# Install dependencies
pip install -r requirements.txt

# Start the server
python -m app.main
```

### 2. Frontend Setup
```bash
cd frontend
# Install dependencies
flutter pub get

# Update notification sounds (optional)
# Add sound files to assets/sounds/
# - new_order.mp3
# - payment_received.mp3
# - urgent_notification.mp3
```

### 3. Integration in Business App
```dart
// In your main business app widget
class BusinessApp extends StatefulWidget {
  @override
  _BusinessAppState createState() => _BusinessAppState();
}

class _BusinessAppState extends State<BusinessApp> {
  final NotificationService _notificationService = NotificationService();
  
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }
  
  Future<void> _initializeNotifications() async {
    // Initialize notification system
    await NotificationService.init();
    
    // Connect to business-specific notifications
    String businessId = await _getCurrentBusinessId();
    String authToken = await _getAuthToken();
    
    await _notificationService.connectToNotifications(businessId, authToken);
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        // Your existing app UI
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationPanel(
                  businessId: businessId,
                  authToken: authToken,
                ),
              ),
            );
          },
          child: Icon(Icons.notifications),
        ),
      ),
    );
  }
}
```

## Testing

### 1. End-to-End Test
Run the comprehensive test script:
```bash
python test_notification_system.py
```

### 2. Manual Testing
1. Start backend server
2. Open business app
3. Simulate customer order creation via API
4. Verify real-time notification delivery
5. Test order status updates

## Features

### Real-time Notifications
- ✅ WebSocket connection with auto-reconnect
- ✅ Multiple notification types
- ✅ Priority levels (low, normal, high, urgent)
- ✅ Connection status monitoring

### Local Notifications
- ✅ Push notifications when app is in background
- ✅ Custom notification sounds per type
- ✅ Rich notification content with actions

### Notification Management
- ✅ Notification history with persistence
- ✅ Mark as read functionality
- ✅ Clear all notifications
- ✅ Notification statistics

### Order Integration
- ✅ Automatic order notification triggering
- ✅ Order status update notifications
- ✅ Payment confirmation notifications
- ✅ Order lifecycle tracking

## Database Schema

The system uses the shared MongoDB database with these collections:

### Orders Collection
```javascript
{
  "_id": ObjectId,
  "order_number": "ORD-20241224-001",
  "business_id": ObjectId,
  "customer_name": "John Doe",
  "items": [...],
  "status": "pending", // pending, confirmed, preparing, ready, delivered
  "payment_info": {...},
  "created_at": ISODate,
  "updated_at": ISODate
}
```

### Notifications Collection (Optional - can use in-memory for real-time)
```javascript
{
  "_id": ObjectId,
  "business_id": ObjectId,
  "type": "new_order",
  "title": "New Order Received",
  "message": "Order #ORD-20241224-001 from John Doe",
  "data": {"order_id": "...", "customer_name": "..."},
  "priority": "high",
  "is_read": false,
  "timestamp": ISODate
}
```

## API Endpoints

### Order Management
- `POST /api/orders?business_id={id}` - Create new order
- `GET /api/orders/{business_id}` - Get business orders
- `PUT /api/orders/{order_id}/status` - Update order status

### Notification Management
- `WS /notifications/ws/notifications/{business_id}` - WebSocket connection
- `GET /notifications/history/{business_id}` - Get notification history
- `POST /notifications/mark-read/{business_id}/{notification_id}` - Mark as read
- `POST /notifications/test/{business_id}` - Send test notification

## Benefits

1. **Real-time Communication**: Instant notifications when orders are placed
2. **Shared Database**: No data synchronization issues between apps
3. **Scalable Architecture**: WebSocket connections support multiple business users
4. **Rich Notifications**: Audio, visual, and interactive notifications
5. **Offline Support**: Notification history persistence and reconnection logic
6. **Order Lifecycle**: Complete tracking from order creation to delivery

This notification system provides a robust foundation for real-time order management between the customer and business applications.
