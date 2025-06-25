#!/usr/bin/env python3
"""
End-to-End Notification System Test
===================================

This script tests the complete notification flow:
1. Customer app creates an order in the shared MongoDB database
2. Backend automatically sends notification to business app
3. Business app receives real-time WebSocket notification
4. Business app can update order status
5. Customer app gets notified of status changes

Since both apps share the same MongoDB database, this simulates real-world usage.
"""

import asyncio
import json
import requests
import websockets
from datetime import datetime
import uuid

# Configuration
BACKEND_URL = "http://localhost:8000"
WS_URL = "ws://localhost:8000"

# Test data
TEST_BUSINESS_ID = "6707d7c17b21313afdcabaed"  # Replace with actual business ID
TEST_ORDER_DATA = {
    "customer_name": "John Doe",
    "customer_phone": "+1234567890",
    "customer_email": "john.doe@example.com",
    "items": [
        {
            "item_id": "item_001",
            "name": "Margherita Pizza",
            "price": 15.99,
            "quantity": 2,
            "special_instructions": "Extra cheese"
        },
        {
            "item_id": "item_002", 
            "name": "Caesar Salad",
            "price": 8.99,
            "quantity": 1,
            "special_instructions": "Dressing on the side"
        }
    ],
    "delivery_type": "delivery",
    "delivery_address": {
        "street": "123 Main St",
        "city": "New York",
        "state": "NY",
        "zip_code": "10001"
    },
    "payment_info": {
        "method": "card",
        "card_last_four": "1234",
        "amount": 40.97,
        "tip": 6.00,
        "tax": 3.68,
        "total": 50.65
    },
    "special_instructions": "Please ring doorbell twice"
}

class NotificationTester:
    def __init__(self):
        self.business_id = TEST_BUSINESS_ID
        self.auth_token = None
        self.ws_connection = None
        self.received_notifications = []

    async def authenticate(self):
        """Simulate authentication (you might need to implement proper auth)"""
        # For testing, we'll use a mock token
        self.auth_token = "test_token_123"
        print("✅ Authenticated successfully")

    async def listen_for_notifications(self):
        """Listen for WebSocket notifications from the business app perspective"""
        try:
            # Connect to notification WebSocket
            ws_url = f"{WS_URL}/notifications/ws/notifications/{self.business_id}"
            print(f"🔗 Connecting to WebSocket: {ws_url}")
            
            async with websockets.connect(ws_url) as websocket:
                self.ws_connection = websocket
                print("✅ Connected to notification WebSocket")
                
                # Listen for notifications
                async for message in websocket:
                    try:
                        notification = json.loads(message)
                        self.received_notifications.append(notification)
                        print(f"📳 Received notification: {notification['title']}")
                        print(f"   Message: {notification['message']}")
                        print(f"   Type: {notification['type']}")
                        print(f"   Priority: {notification['priority']}")
                        print(f"   Data: {notification['data']}")
                        
                        # If it's a new order notification, simulate business response
                        if notification['type'] == 'new_order':
                            await self.handle_new_order(notification)
                            
                    except json.JSONDecodeError as e:
                        print(f"❌ Error parsing notification: {e}")
                        
        except Exception as e:
            print(f"❌ WebSocket connection error: {e}")

    async def handle_new_order(self, notification):
        """Simulate business handling a new order"""
        order_id = notification['data'].get('order_id')
        if order_id:
            print(f"👨‍🍳 Business processing order {order_id}")
            
            # Simulate business confirming the order after 2 seconds
            await asyncio.sleep(2)
            await self.update_order_status(order_id, "confirmed")
            
            # Simulate preparation after 5 seconds
            await asyncio.sleep(5)
            await self.update_order_status(order_id, "preparing")
            
            # Simulate ready for pickup/delivery after 10 seconds
            await asyncio.sleep(10)
            await self.update_order_status(order_id, "ready")

    async def update_order_status(self, order_id, status):
        """Update order status (business app functionality)"""
        try:
            url = f"{BACKEND_URL}/api/orders/{order_id}/status"
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.auth_token}"
            }
            data = {
                "status": status,
                "updated_at": datetime.now().isoformat()
            }
            
            response = requests.put(url, headers=headers, json=data)
            if response.status_code == 200:
                print(f"✅ Order {order_id} status updated to: {status}")
            else:
                print(f"❌ Failed to update order status: {response.status_code}")
                
        except Exception as e:
            print(f"❌ Error updating order status: {e}")

    def simulate_customer_order(self):
        """Simulate customer app creating an order"""
        try:
            url = f"{BACKEND_URL}/api/orders"
            headers = {"Content-Type": "application/json"}
            params = {"business_id": self.business_id}
            
            print("🛒 Customer placing order...")
            print(f"   Customer: {TEST_ORDER_DATA['customer_name']}")
            print(f"   Items: {len(TEST_ORDER_DATA['items'])} items")
            print(f"   Total: ${TEST_ORDER_DATA['payment_info']['total']}")
            
            response = requests.post(url, headers=headers, params=params, json=TEST_ORDER_DATA)
            
            if response.status_code == 201:
                order = response.json()
                print(f"✅ Order created successfully!")
                print(f"   Order ID: {order['id']}")
                print(f"   Order Number: {order['order_number']}")
                return order
            else:
                print(f"❌ Failed to create order: {response.status_code}")
                print(f"   Response: {response.text}")
                return None
                
        except Exception as e:
            print(f"❌ Error creating order: {e}")
            return None

    async def test_notification_history(self):
        """Test retrieving notification history"""
        try:
            url = f"{BACKEND_URL}/notifications/history/{self.business_id}"
            headers = {"Authorization": f"Bearer {self.auth_token}"}
            
            response = requests.get(url, headers=headers)
            if response.status_code == 200:
                history = response.json()
                print(f"📜 Notification history: {len(history)} notifications")
                for notification in history[:3]:  # Show last 3
                    print(f"   - {notification['title']}: {notification['message']}")
            else:
                print(f"❌ Failed to get notification history: {response.status_code}")
                
        except Exception as e:
            print(f"❌ Error getting notification history: {e}")

    async def test_send_test_notification(self):
        """Test sending a test notification"""
        try:
            url = f"{BACKEND_URL}/notifications/test/{self.business_id}"
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.auth_token}"
            }
            data = {
                "title": "Test Notification",
                "message": "This is a test notification from the end-to-end test",
                "type": "test",
                "priority": "normal"
            }
            
            response = requests.post(url, headers=headers, json=data)
            if response.status_code == 200:
                print("✅ Test notification sent successfully")
            else:
                print(f"❌ Failed to send test notification: {response.status_code}")
                
        except Exception as e:
            print(f"❌ Error sending test notification: {e}")

    async def run_test(self):
        """Run the complete end-to-end test"""
        print("🚀 Starting End-to-End Notification System Test")
        print("=" * 60)
        
        # Step 1: Authenticate
        await self.authenticate()
        
        # Step 2: Send test notification
        print("\n📤 Testing notification sending...")
        await self.test_send_test_notification()
        
        # Step 3: Start listening for notifications in the background
        print("\n👂 Starting notification listener...")
        notification_task = asyncio.create_task(self.listen_for_notifications())
        
        # Give WebSocket time to connect
        await asyncio.sleep(2)
        
        # Step 4: Simulate customer creating an order
        print("\n📱 Simulating customer app order creation...")
        order = self.simulate_customer_order()
        
        if order:
            # Step 5: Wait for notifications and order processing
            print("\n⏳ Waiting for notifications and order processing...")
            await asyncio.sleep(20)  # Wait for order processing simulation
            
            # Step 6: Test notification history
            print("\n📚 Testing notification history...")
            await self.test_notification_history()
            
            # Step 7: Show summary
            print("\n📊 Test Summary:")
            print(f"   Notifications received: {len(self.received_notifications)}")
            for i, notification in enumerate(self.received_notifications, 1):
                print(f"   {i}. {notification['type']}: {notification['title']}")
        
        # Cleanup
        if notification_task:
            notification_task.cancel()
        
        print("\n✅ End-to-End Test Completed!")

async def main():
    """Main test function"""
    tester = NotificationTester()
    await tester.run_test()

if __name__ == "__main__":
    print("🧪 Notification System End-to-End Test")
    print("This test simulates the complete flow between customer and business apps")
    print("Make sure the backend server is running on localhost:8000\n")
    
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n⏹️  Test interrupted by user")
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
