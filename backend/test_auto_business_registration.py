"""
Test script to verify automatic business creation during user registration.
"""
import asyncio
import httpx
import time


async def test_registration_with_business_creation():
    """Test that registration automatically creates a business."""
    timestamp = str(int(time.time()))
    base_url = "http://localhost:8001"
    
    # Registration data matching frontend format
    registration_data = {
        "email": f"test_auto_business_{timestamp}@example.com",
        "password": "TestPassword123!",
        "business_name": "Auto-Created Test Business",
        "business_type": "restaurant",
        "phone_number": "+9647701234567",
        "owner_name": "Test Owner",
        "national_id": "1234567890",
        "date_of_birth": "1990-05-15",
        "address": {
            "country": "Iraq",
            "city": "Baghdad",
            "district": "Karrada",
            "neighbourhood": "Al-Jadriya",
            "street": "Main Street",
            "building_number": "123",
            "zip_code": "10001"
        }
    }
    
    async with httpx.AsyncClient() as client:
        print("🚀 Testing user registration with automatic business creation...")
        
        # Step 1: Register user
        print("\n1️⃣ Registering user...")
        register_response = await client.post(
            f"{base_url}/auth/register",
            json=registration_data,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"Registration status: {register_response.status_code}")
        if register_response.status_code != 201:
            print(f"❌ Registration failed: {register_response.text}")
            return False
            
        user_data = register_response.json()
        print(f"✅ User created: {user_data['email']} (ID: {user_data['id']})")
        
        # Step 2: Login to get access token
        print("\n2️⃣ Logging in...")
        login_response = await client.post(
            f"{base_url}/auth/jwt/login",
            data={
                "username": registration_data["email"],
                "password": registration_data["password"]
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"}
        )
        
        if login_response.status_code != 200:
            print(f"❌ Login failed: {login_response.text}")
            return False
            
        token_data = login_response.json()
        access_token = token_data["access_token"]
        print(f"✅ Login successful, got access token")
        
        # Step 3: Check if businesses were automatically created
        print("\n3️⃣ Checking for automatically created businesses...")
        businesses_response = await client.get(
            f"{base_url}/businesses/my-businesses",
            headers={"Authorization": f"Bearer {access_token}"}
        )
        
        if businesses_response.status_code != 200:
            print(f"❌ Failed to fetch businesses: {businesses_response.text}")
            return False
            
        businesses = businesses_response.json()
        print(f"✅ Found {len(businesses)} business(es)")
        
        if len(businesses) == 0:
            print("⚠️ No businesses found - automatic creation might have failed")
            return False
        
        # Display business details
        for business in businesses:
            print(f"\n📋 Business Details:")
            print(f"   Name: {business['name']}")
            print(f"   Type: {business['business_type']}")
            print(f"   ID: {business['id']}")
            print(f"   Owner: {business.get('owner_name', 'N/A')}")
            print(f"   Phone: {business['phone_number']}")
            print(f"   Email: {business['email']}")
            print(f"   Status: {business['status']}")
            
        print(f"\n🎉 SUCCESS! Registration automatically created user and business(es)")
        return True


async def main():
    """Main test function."""
    try:
        success = await test_registration_with_business_creation()
        if success:
            print("\n✅ All tests passed! Automatic business creation is working.")
        else:
            print("\n❌ Tests failed!")
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(main())
