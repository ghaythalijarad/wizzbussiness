#!/usr/bin/env python3
"""
Test script to verify the item management backend functionality
and create sample categories for testing the dropdown.
"""

import requests
import json
import sys

# Configuration
BASE_URL = "http://localhost:8000"
TEST_USER = {
    "email": "test@example.com",
    "password": "testpassword123"
}

def login():
    """Login and get access token"""
    try:
        response = requests.post(
            f"{BASE_URL}/auth/jwt/login",
            data={
                "username": TEST_USER["email"],
                "password": TEST_USER["password"]
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"}
        )
        
        if response.status_code == 200:
            token = response.json()["access_token"]
            print(f"✅ Login successful")
            return token
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
        response = requests.get(f"{BASE_URL}/auth/me", headers=headers)
        
        if response.status_code == 200:
            user_data = response.json()
            business_id = user_data.get("business_id")
            print(f"✅ User business ID: {business_id}")
            return business_id
        else:
            print(f"❌ Failed to get user info: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"❌ Error getting user info: {e}")
        return None

def get_categories(token, business_id):
    """Get existing categories"""
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.get(
            f"{BASE_URL}/api/categories?business_id={business_id}",
            headers=headers
        )
        
        if response.status_code == 200:
            categories = response.json()
            print(f"✅ Found {len(categories)} existing categories")
            for cat in categories:
                print(f"  - {cat['name']} (ID: {cat['id']})")
            return categories
        else:
            print(f"❌ Failed to get categories: {response.status_code} - {response.text}")
            return []
    except Exception as e:
        print(f"❌ Error getting categories: {e}")
        return []

def create_category(token, business_id, name, description=""):
    """Create a new category"""
    try:
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        data = {
            "name": name,
            "description": description,
            "display_order": 0
        }
        
        response = requests.post(
            f"{BASE_URL}/api/categories?business_id={business_id}",
            headers=headers,
            json=data
        )
        
        if response.status_code == 200:
            category = response.json()
            print(f"✅ Created category: {category['name']} (ID: {category['id']})")
            return category
        else:
            print(f"❌ Failed to create category '{name}': {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"❌ Error creating category '{name}': {e}")
        return None

def main():
    print("🧪 Testing Item Management Backend\n")
    
    # Step 1: Login
    print("1. Attempting login...")
    token = login()
    if not token:
        print("❌ Cannot proceed without authentication")
        sys.exit(1)
    
    # Step 2: Get user business
    print("\n2. Getting user business...")
    business_id = get_user_business(token)
    if not business_id:
        print("❌ Cannot proceed without business ID")
        sys.exit(1)
    
    # Step 3: Check existing categories
    print("\n3. Checking existing categories...")
    categories = get_categories(token, business_id)
    
    # Step 4: Create sample categories if none exist
    if len(categories) == 0:
        print("\n4. Creating sample categories...")
        sample_categories = [
            ("Appetizers", "Starters and small plates"),
            ("Main Courses", "Full meals and entrees"), 
            ("Beverages", "Drinks and refreshments"),
            ("Desserts", "Sweet treats and desserts")
        ]
        
        for name, desc in sample_categories:
            create_category(token, business_id, name, desc)
    else:
        print(f"\n4. ✅ {len(categories)} categories already exist, skipping creation")
    
    # Step 5: Verify final state
    print("\n5. Final verification...")
    final_categories = get_categories(token, business_id)
    
    if len(final_categories) > 0:
        print(f"\n🎉 Success! The dropdown should now work with {len(final_categories)} categories:")
        for cat in final_categories:
            print(f"  ✓ {cat['name']}")
        print(f"\nBusiness ID for testing: {business_id}")
        print("You can now test the dropdown in the Flutter app!")
    else:
        print("\n❌ No categories available. The dropdown will show 'Create First Category' option.")

if __name__ == "__main__":
    main()
