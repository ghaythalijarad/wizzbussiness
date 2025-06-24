#!/usr/bin/env python3
"""
Test script to verify item creation API fix
"""
import requests
import json

# Configuration
BASE_URL = "http://192.168.31.7:8000"
BUSINESS_ID = "685aa530c2b642b9cdffda64"  # The business created during registration

def get_auth_token():
    """Get authentication token using the test user credentials"""
    login_data = {
        "username": "saif@yahoo.com",
        "password": "Gha@551987"
    }
    
    response = requests.post(
        f"{BASE_URL}/auth/jwt/login",
        data=login_data,
        headers={"Content-Type": "application/x-www-form-urlencoded"}
    )
    
    if response.status_code == 200:
        token_data = response.json()
        return token_data["access_token"]
    else:
        print(f"Login failed: {response.status_code} - {response.text}")
        return None

def test_categories_endpoint():
    """Test the categories endpoint with trailing slash"""
    token = get_auth_token()
    if not token:
        return False
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    print("Testing categories endpoint with trailing slash...")
    
    # Test with trailing slash (correct)
    response = requests.get(
        f"{BASE_URL}/api/categories/?business_id={BUSINESS_ID}",
        headers=headers
    )
    
    print(f"GET /api/categories/ - Status: {response.status_code}")
    if response.status_code == 200:
        categories = response.json()
        print(f"Found {len(categories)} categories")
        return categories
    else:
        print(f"Error: {response.text}")
        return None

def test_item_creation():
    """Test item creation with trailing slash"""
    token = get_auth_token()
    if not token:
        return False
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # Get categories first
    categories = test_categories_endpoint()
    if not categories:
        print("Cannot test item creation without categories")
        return False
    
    category_id = categories[0]["id"]
    
    print("\\nTesting item creation with trailing slash...")
    
    # Test item creation data
    item_data = {
        "name": "Test Medicine",
        "description": "A test medicine for API testing",
        "price": 10.99,
        "category_id": category_id,
        "is_available": True,
        "stock_quantity": 100,
        "sku": "TEST001",
        "barcode": "1234567890123",
        "item_type": "medicine"
    }
    
    # Test with trailing slash (correct)
    response = requests.post(
        f"{BASE_URL}/api/items/?business_id={BUSINESS_ID}",
        headers=headers,
        data=json.dumps(item_data)
    )
    
    print(f"POST /api/items/ - Status: {response.status_code}")
    if response.status_code == 200:
        item = response.json()
        print(f"✅ Item created successfully: {item.get('name', 'Unknown')}")
        print(f"Item ID: {item.get('id', 'Unknown')}")
        return True
    else:
        print(f"❌ Error creating item: {response.text}")
        return False

def test_without_trailing_slash():
    """Test what happens without trailing slash (should redirect)"""
    token = get_auth_token()
    if not token:
        return False
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    print("\\nTesting categories endpoint WITHOUT trailing slash...")
    
    # Test without trailing slash (should redirect)
    response = requests.get(
        f"{BASE_URL}/api/categories?business_id={BUSINESS_ID}",
        headers=headers,
        allow_redirects=True  # Follow redirects
    )
    
    print(f"GET /api/categories - Status: {response.status_code}")
    print(f"Final URL: {response.url}")
    
    if response.status_code == 200:
        print("✅ Redirect handled correctly")
        return True
    else:
        print(f"❌ Error: {response.text}")
        return False

def main():
    print("=== Testing Item Creation API Fix ===\\n")
    
    # Test 1: Categories with trailing slash
    print("1. Testing categories endpoint...")
    categories_success = test_categories_endpoint() is not None
    
    # Test 2: Item creation with trailing slash
    print("\\n2. Testing item creation...")
    item_creation_success = test_item_creation()
    
    # Test 3: Without trailing slash (should work due to redirects)
    print("\\n3. Testing redirect handling...")
    redirect_success = test_without_trailing_slash()
    
    print("\\n=== Test Results ===")
    print(f"Categories endpoint: {'✅ PASS' if categories_success else '❌ FAIL'}")
    print(f"Item creation: {'✅ PASS' if item_creation_success else '❌ FAIL'}")
    print(f"Redirect handling: {'✅ PASS' if redirect_success else '❌ FAIL'}")
    
    if categories_success and item_creation_success:
        print("\\n🎉 All tests passed! Item creation should now work in the Flutter app.")
    else:
        print("\\n❌ Some tests failed. Check the API configuration.")

if __name__ == "__main__":
    main()
