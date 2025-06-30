#!/usr/bin/env python3
"""
Test script to verify order simulation functionality
"""
import requests
import json
from datetime import datetime

def test_order_creation():
    """Test creating a simulated order via API"""
    
    # API endpoint
    base_url = "http://127.0.0.1:8000"
    
    # Sample business ID (valid MongoDB ObjectId format)
    business_id = "507f1f77bcf86cd799439011"  # Valid 24-character hex string
    
    # Sample order data matching the backend OrderCreateSchema
    order_data = {
        "customer_name": "Ahmed Al-Rashid",
        "customer_phone": "+971501234567",
        "customer_email": "ahmed.alrashid@example.com",
        "customer_id": "sim_customer_12345",
        "items": [
            {
                "item_id": "sim_123",
                "item_name": "Chicken Shawarma Wrap",
                "quantity": 2,
                "unit_price": 45.0,
                "total_price": 90.0,
                "special_instructions": "Extra spicy"
            },
            {
                "item_id": "sim_456",
                "item_name": "Hummus with Pita",
                "quantity": 1,
                "unit_price": 25.0,
                "total_price": 25.0,
                "special_instructions": None
            }
        ],
        "delivery_type": "delivery",
        "delivery_address": {
            "street": "Downtown Dubai, Burj Khalifa District, Tower 1, Apt 501",
            "district": "Downtown Dubai",
            "city": "Dubai",
            "country": "UAE",
            "zip_code": "00000",
            "latitude": 25.2048,
            "longitude": 55.2708
        },
        "delivery_notes": "Please call when you arrive",
        "special_instructions": "Handle with care",
        "payment_info": {
            "payment_method": "cash_on_delivery",
            "subtotal": 115.0,
            "tax_amount": 5.75,
            "delivery_fee": 10.0,
            "total_amount": 130.75
        }
    }
    
    try:
        # Make API call
        url = f"{base_url}/api/orders/?business_id={business_id}"
        headers = {
            "Content-Type": "application/json",
            # Note: In a real scenario, you'd need proper authentication headers
        }
        
        print(f"Testing order creation at: {url}")
        print(f"Order data: {json.dumps(order_data, indent=2)}")
        
        response = requests.post(url, json=order_data, headers=headers)
        
        print(f"\nResponse Status: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        
        if response.status_code == 201:
            result = response.json()
            print(f"✅ Order created successfully!")
            print(f"Order ID: {result.get('id', 'N/A')}")
            print(f"Order Number: {result.get('order_number', 'N/A')}")
            print(f"Customer: {result.get('customer_name', 'N/A')}")
            print(f"Total: ${result.get('total_amount', 'N/A')}")
        else:
            print(f"❌ Order creation failed!")
            print(f"Error: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection failed! Make sure the backend server is running on http://127.0.0.1:8000")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

if __name__ == "__main__":
    print("🧪 Testing Order Simulation API")
    print("=" * 40)
    test_order_creation()
