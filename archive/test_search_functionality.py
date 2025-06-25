#!/usr/bin/env python3
"""
Test script to verify the backend search functionality for items.
"""

import requests
import json
import sys

# Configuration
BASE_URL = "http://localhost:8000"
TEST_USER = {
    "email": "saif@yahoo.com",
    "password": "Gha@551987"
}

def login():
    """Login and get access token"""
    try:
        response = requests.post(
            f"{BASE_URL}/auth/jwt/login",
            data={
                "username": TEST_USER["email"],
                "password": TEST_USER["password"]
            }
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Login successful")
            return data["access_token"]
        else:
            print(f"❌ Login failed: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"❌ Login error: {e}")
        return None

def get_user_business(token):
    """Get the user's business information"""
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.get(
            f"{BASE_URL}/businesses/my-businesses",
            headers=headers
        )
        
        if response.status_code == 200:
            businesses = response.json()
            if businesses:
                business = businesses[0]
                print(f"✅ Found business: {business['name']} (ID: {business['id']})")
                return business['id']
            else:
                print("❌ No businesses found")
                return None
        else:
            print(f"❌ Failed to get business: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"❌ Error getting business: {e}")
        return None

def test_search_items(token, business_id, query=""):
    """Test the items search endpoint"""
    try:
        headers = {"Authorization": f"Bearer {token}"}
        params = {"business_id": business_id}
        
        if query:
            params["query"] = query
            
        response = requests.get(
            f"{BASE_URL}/api/items/",
            headers=headers,
            params=params
        )
        
        print(f"\n🔍 Testing search with query: '{query}'")
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            items = data.get("items", [])
            total = data.get("total", 0)
            
            print(f"✅ Search successful!")
            print(f"   Total items found: {total}")
            print(f"   Items returned: {len(items)}")
            
            for item in items[:3]:  # Show first 3 items
                print(f"   - {item['name']} (ID: {item['id']}) - IQD {item['price']}")
                print(f"     Category: {item.get('category_name', 'N/A')}")
            
            if len(items) > 3:
                print(f"   ... and {len(items) - 3} more items")
                
            return True
        else:
            print(f"❌ Search failed: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Search error: {e}")
        return False

def main():
    print("🧪 Testing Backend Search Functionality")
    print("=" * 50)
    
    # Login
    token = login()
    if not token:
        sys.exit(1)
    
    # Get business
    business_id = get_user_business(token)
    if not business_id:
        sys.exit(1)
    
    # Test search scenarios
    test_cases = [
        "",  # No query - should return all items
        "medicine",  # General search
        "pain",  # Specific search
        "xyz123",  # No results expected
    ]
    
    print(f"\n🧪 Running search tests...")
    success_count = 0
    
    for query in test_cases:
        if test_search_items(token, business_id, query):
            success_count += 1
    
    print(f"\n📊 Results: {success_count}/{len(test_cases)} tests passed")
    
    if success_count == len(test_cases):
        print("🎉 All search tests passed!")
    else:
        print("⚠️  Some search tests failed")

if __name__ == "__main__":
    main()
