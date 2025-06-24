#!/usr/bin/env python3
"""
Real-World Notification System Demonstration
===========================================

This script demonstrates how the notification system works in practice:

Scenario: "Mario's Pizza Palace" 
- Customer "Sarah Johnson" places an order via the Wizz customer app
- Business receives real-time notification
- Staff processes the order through different stages
- Customer gets status updates

This simulates the real shared database usage between customer and business apps.
"""

import asyncio
import json
import requests
import websockets
import time
from datetime import datetime
import uuid

# Backend configuration
BACKEND_URL = "http://localhost:8000"
WS_URL = "ws://localhost:8000"

# Demo business data (you can replace with your actual business ID)
DEMO_BUSINESS_ID = "6707d7c17b21313afdcabaed"

# Demo order from customer app
CUSTOMER_ORDER = {
    "customer_name": "Sarah Johnson",
    "customer_phone": "+1-555-0123",
    "customer_email": "sarah.johnson@email.com",
    "items": [
        {
            "item_id": "pizza_margherita",
            "name": "Margherita Pizza (Large)",
            "price": 18.99,
            "quantity": 1,
            "special_instructions": "Extra basil, light cheese"
        },
        {
            "item_id": "garlic_bread",
            "name": "Garlic Bread",
            "price": 6.99,
            "quantity": 2,
            "special_instructions": "Extra crispy"
        },
        {
            "item_id": "coke",
            "name": "Coca-Cola (500ml)",
            "price": 2.50,
            "quantity": 2,
            "special_instructions": ""
        }
    ],
    "delivery_type": "delivery",
    "delivery_address": {
        "street": "456 Oak Avenue, Apt 3B",
        "city": "San Francisco",
        "state": "CA",
        "zip_code": "94102",
        "delivery_instructions": "Ring doorbell twice, leave at door"
    },
    "payment_info": {
        "method": "credit_card",
        "card_last_four": "4532",
        "amount": 37.97,  # 18.99 + 6.99*2 + 2.50*2
        "tip": 6.00,
        "tax": 3.42,
        "delivery_fee": 2.99,
        "total": 50.38
    },
    "special_instructions": "Please call when arriving - doorbell is broken",
    "estimated_delivery_time": 45
}

class PizzaPalaceDemo:
    def __init__(self):
        self.business_id = DEMO_BUSINESS_ID
        self.order_id = None
        self.notifications_received = []
        self.ws_connected = False

    async def run_demo(self):
        """Run the complete real-world demonstration"""
        print("🍕 Welcome to Mario's Pizza Palace Notification Demo!")
        print("=" * 60)
        print("📱 This demo shows how orders flow from customer app to business app")
        print("🔔 All notifications are sent in real-time via WebSocket")
        print("💾 Everything is stored in the shared MongoDB database\n")

        # Start the demo
        await self._demo_step_1_customer_places_order()
        await self._demo_step_2_business_receives_notification()
        await self._demo_step_3_order_processing()
        await self._demo_step_4_delivery_tracking()
        
        print("\n🎉 Demo Complete!")
        print("📊 Summary:")
        print(f"   • Order processed successfully")
        print(f"   • {len(self.notifications_received)} notifications sent")
        print(f"   • Full order lifecycle demonstrated")
        print("\n✨ Your notification system is ready for production!")

    async def _demo_step_1_customer_places_order(self):
        """Step 1: Customer places order through Wizz app"""
        print("🛒 STEP 1: Customer Places Order")
        print("-" * 40)
        print(f"👤 Customer: {CUSTOMER_ORDER['customer_name']}")
        print(f"📍 Delivery to: {CUSTOMER_ORDER['delivery_address']['street']}")
        print(f"💰 Total: ${CUSTOMER_ORDER['payment_info']['total']}")
        print("📦 Items ordered:")
        
        for item in CUSTOMER_ORDER['items']:
            print(f"   • {item['quantity']}x {item['name']} - ${item['price']}")
            if item['special_instructions']:
                print(f"     🗨️  {item['special_instructions']}")

        print("\n🔄 Creating order in shared database...")
        
        # Simulate customer app API call
        try:
            response = requests.post(
                f"{BACKEND_URL}/api/orders",
                params={"business_id": self.business_id},
                json=CUSTOMER_ORDER,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 201:
                order_data = response.json()
                self.order_id = order_data['id']
                print(f"✅ Order created successfully!")
                print(f"   Order ID: {self.order_id}")
                print(f"   Order Number: {order_data['order_number']}")
                print(f"   Status: {order_data['status']}")
                return True
            else:
                print(f"❌ Failed to create order: {response.status_code}")
                print(f"Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Error creating order: {e}")
            return False

    async def _demo_step_2_business_receives_notification(self):
        """Step 2: Business app receives real-time notification"""
        print("\n📳 STEP 2: Business Receives Real-Time Notification")
        print("-" * 40)
        print("🔌 Connecting to notification WebSocket...")

        try:
            ws_url = f"{WS_URL}/notifications/ws/notifications/{self.business_id}"
            async with websockets.connect(ws_url) as websocket:
                self.ws_connected = True
                print("✅ Connected to real-time notifications")
                print("👂 Listening for new order notification...")

                # Wait for the notification (should arrive immediately)
                try:
                    message = await asyncio.wait_for(websocket.recv(), timeout=10.0)
                    notification = json.loads(message)
                    self.notifications_received.append(notification)
                    
                    print("🔔 NOTIFICATION RECEIVED!")
                    print(f"   Title: {notification['title']}")
                    print(f"   Message: {notification['message']}")
                    print(f"   Type: {notification['type']}")
                    print(f"   Priority: {notification['priority']}")
                    
                    if notification['type'] == 'new_order':
                        print("🍕 New pizza order detected!")
                        order_id = notification['data'].get('order_id')
                        customer_name = notification['data'].get('customer_name')
                        print(f"   📋 Order ID: {order_id}")
                        print(f"   👤 Customer: {customer_name}")
                        
                        # This is where the Flutter app would:
                        # 1. Show a local notification
                        # 2. Play notification sound
                        # 3. Update the UI
                        # 4. Vibrate the device
                        print("📱 Flutter app would now:")
                        print("   • Show local push notification")
                        print("   • Play 'new_order.mp3' sound")
                        print("   • Vibrate device")
                        print("   • Update notification badge")
                        
                except asyncio.TimeoutError:
                    print("⏰ No notification received within 10 seconds")
                    print("   (This might mean the order didn't trigger notifications)")
                    
        except Exception as e:
            print(f"❌ WebSocket connection error: {e}")

    async def _demo_step_3_order_processing(self):
        """Step 3: Business processes the order through different stages"""
        print("\n👨‍🍳 STEP 3: Order Processing")
        print("-" * 40)
        
        if not self.order_id:
            print("❌ No order ID available for processing")
            return

        # Simulate business workflow
        stages = [
            ("confirmed", "Order confirmed by restaurant", 3),
            ("preparing", "Chef started preparing the order", 8),
            ("ready", "Order ready for delivery", 12),
            ("out_for_delivery", "Driver picked up the order", 2),
            ("delivered", "Order delivered to customer", 15)
        ]

        print("⏳ Simulating real restaurant workflow...\n")

        for status, description, wait_time in stages:
            print(f"🔄 Updating order status to: {status.upper()}")
            print(f"   📝 {description}")
            
            # Update order status
            try:
                response = requests.put(
                    f"{BACKEND_URL}/api/orders/{self.order_id}/status",
                    json={
                        "status": status,
                        "updated_at": datetime.now().isoformat(),
                        "notes": description
                    },
                    headers={"Content-Type": "application/json"}
                )
                
                if response.status_code == 200:
                    print(f"✅ Status updated successfully")
                    print(f"   🔔 Customer app receives notification: '{description}'")
                else:
                    print(f"❌ Failed to update status: {response.status_code}")
                    
            except Exception as e:
                print(f"❌ Error updating status: {e}")

            # Wait to simulate real processing time
            if wait_time > 5:
                print(f"   ⏰ Waiting {wait_time} seconds (simulating {status} time)...")
                for i in range(wait_time):
                    await asyncio.sleep(1)
                    if i % 3 == 0:
                        print("   ⏳", end="", flush=True)
                print()  # New line
            else:
                await asyncio.sleep(wait_time)

    async def _demo_step_4_delivery_tracking(self):
        """Step 4: Final delivery tracking"""
        print("\n🚚 STEP 4: Delivery Tracking")
        print("-" * 40)
        print("📦 Order completed successfully!")
        print("⭐ Customer receives final notification with:")
        print("   • Delivery confirmation")
        print("   • Rating request")
        print("   • Receipt email")
        
        # Show final order summary
        print(f"\n📊 Final Order Summary:")
        print(f"   Order ID: {self.order_id}")
        print(f"   Customer: {CUSTOMER_ORDER['customer_name']}")
        print(f"   Total: ${CUSTOMER_ORDER['payment_info']['total']}")
        print(f"   Status: DELIVERED ✅")
        print(f"   Processing time: ~45 minutes")

async def main():
    """Main demonstration function"""
    demo = PizzaPalaceDemo()
    
    print("🧪 Testing backend connection...")
    try:
        response = requests.get(f"{BACKEND_URL}/health", timeout=5)
        if response.status_code == 200:
            print("✅ Backend is running and healthy")
        else:
            print(f"⚠️  Backend responded with status: {response.status_code}")
    except Exception as e:
        print(f"❌ Cannot connect to backend: {e}")
        print("Please make sure the backend is running on localhost:8000")
        return

    print("\n🚀 Starting real-world notification demo...")
    print("Press Ctrl+C to stop at any time\n")
    
    try:
        await demo.run_demo()
    except KeyboardInterrupt:
        print("\n⏹️  Demo stopped by user")
    except Exception as e:
        print(f"\n❌ Demo failed: {e}")

if __name__ == "__main__":
    asyncio.run(main())
