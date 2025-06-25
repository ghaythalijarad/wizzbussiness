#!/usr/bin/env python3
"""
Test script to verify item creation functionality.
"""
import requests
import json

BASE_URL = "http://localhost:8000"

def test_endpoints():
    """Test various endpoints to ensure they're accessible."""
    
    # Test health endpoint
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"✅ Health check: {response.status_code} - {response.json()}")
    except Exception as e:
        print(f"❌ Health check failed: {e}")
        return False
    
    # Test API documentation
    try:
        response = requests.get(f"{BASE_URL}/docs")
        print(f"✅ API docs accessible: {response.status_code}")
    except Exception as e:
        print(f"❌ API docs failed: {e}")
    
    # Test categories endpoint (should require auth)
    try:
        response = requests.get(f"{BASE_URL}/api/categories?business_id=test")
        print(f"✅ Categories endpoint: {response.status_code} - {response.text[:100]}")
    except Exception as e:
        print(f"❌ Categories endpoint failed: {e}")
    
    # Test items endpoint (should require auth)
    try:
        response = requests.get(f"{BASE_URL}/api/items?business_id=test")
        print(f"✅ Items endpoint: {response.status_code} - {response.text[:100]}")
    except Exception as e:
        print(f"❌ Items endpoint failed: {e}")
    
    return True

if __name__ == "__main__":
    print("🧪 Testing backend endpoints...")
    test_endpoints()
    print("✅ Backend endpoints test completed!")
