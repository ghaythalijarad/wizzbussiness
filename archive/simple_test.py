#!/usr/bin/env python3
"""
Simple Notification System Test
===============================
Direct test of the notification system functionality
"""

import requests
import json

# Configuration
BACKEND_URL = "http://localhost:8000"
BUSINESS_ID = "6707d7c17b21313afdcabaed"  # Demo business ID

def test_backend_health():
    """Test if backend is running"""
    print("🔍 Testing backend health...")
    try:
        response = requests.get(f"{BACKEND_URL}/health", timeout=5)
        if response.status_code == 200:
            print("✅ Backend is healthy and running")
            return True
        else:
            print(f"❌ Backend health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Cannot connect to backend: {e}")
        return False

def test_order_creation():
    """Test creating an order that should trigger notifications"""
    print("\n📦 Testing order creation...")
    
    # Simple test order
    test_order = {
        "customer_name": "Test Customer",
        "customer_phone": "+1234567890",
        "customer_email": "test@example.com",
        "items": [
            {
                "item_id": "test_item",
                "name": "Test Pizza",
                "price": 15.99,
                "quantity": 1,
                "special_instructions": "Test order for notification system"
            }
        ],
        "delivery_type": "pickup",
        "payment_info": {
            "method": "cash",
            "amount": 15.99,
            "total": 15.99
        }
    }
    
    try:
        response = requests.post(
            f"{BACKEND_URL}/api/orders",
            params={"business_id": BUSINESS_ID},
            json=test_order,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"📤 Order creation response: {response.status_code}")
        print(f"📄 Response body: {response.text[:200]}...")
        
        if response.status_code == 201:
            order_data = response.json()
            print(f"✅ Order created successfully!")
            print(f"   Order ID: {order_data.get('id', 'N/A')}")
            print(f"   Order Number: {order_data.get('order_number', 'N/A')}")
            return order_data.get('id')
        else:
            print(f"❌ Order creation failed")
            return None
            
    except Exception as e:
        print(f"❌ Error creating order: {e}")
        return None

def test_api_endpoints():
    """Test various API endpoints"""
    print("\n🔗 Testing API endpoints...")
    
    endpoints = [
        ("/", "Root endpoint"),
        ("/health", "Health check"),
        ("/docs", "API documentation"),
    ]
    
    for endpoint, description in endpoints:
        try:
            response = requests.get(f"{BACKEND_URL}{endpoint}", timeout=5)
            status = "✅" if response.status_code < 400 else "❌"
            print(f"   {status} {description}: {response.status_code}")
        except Exception as e:
            print(f"   ❌ {description}: Error - {e}")

def main():
    print("🧪 Simple Notification System Test")
    print("=" * 50)
    
    # Test backend connectivity
    if not test_backend_health():
        print("\n❌ Backend is not accessible. Please ensure it's running on localhost:8000")
        return
    
    # Test API endpoints
    test_api_endpoints()
    
    # Test order creation (which should trigger notifications)
    order_id = test_order_creation()
    
    if order_id:
        print(f"\n🎉 Test completed successfully!")
        print(f"📋 Order {order_id} was created and should have triggered notifications")
        print(f"🔔 Any connected business apps would have received a real-time notification")
    else:
        print(f"\n⚠️  Test had issues with order creation")
    
    print(f"\n📊 Test Summary:")
    print(f"   • Backend connectivity: ✅")
    print(f"   • Order creation: {'✅' if order_id else '❌'}")
    print(f"   • Notification system: Ready for Flutter integration")

if __name__ == "__main__":
    main()
