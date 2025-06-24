"""
Comprehensive test to verify the complete registration and login flow
with automatic business creation.
"""
import asyncio
import httpx
import time
import json


async def test_complete_flow():
    """Test the complete user registration and login flow."""
    timestamp = str(int(time.time()))
    base_url = "http://localhost:8001"
    
    # Registration data matching the frontend format exactly
    registration_data = {
        "email": f"fulltest_{timestamp}@example.com",
        "password": "TestPassword123!",
        "business_name": "Complete Flow Test Restaurant",
        "business_type": "restaurant",
        "phone_number": "+9647701234567",
        "owner_name": "Complete Test Owner",
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
    
    print("🚀 Starting Complete Registration & Login Flow Test")
    print("=" * 60)
    
    async with httpx.AsyncClient() as client:
        # Step 1: Register user
        print("\n1️⃣ STEP 1: User Registration")
        print("-" * 30)
        register_response = await client.post(
            f"{base_url}/auth/register",
            json=registration_data,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"Registration Status: {register_response.status_code}")
        if register_response.status_code != 201:
            print(f"❌ Registration failed: {register_response.text}")
            return False
            
        user_data = register_response.json()
        print(f"✅ User created successfully:")
        print(f"   Email: {user_data['email']}")
        print(f"   ID: {user_data['id']}")
        print(f"   Business Name: {user_data['business_name']}")
        print(f"   Business Type: {user_data['business_type']}")
        
        # Step 2: Login to get access token
        print("\n2️⃣ STEP 2: User Login")
        print("-" * 30)
        login_response = await client.post(
            f"{base_url}/auth/jwt/login",
            data={
                "username": registration_data["email"],
                "password": registration_data["password"]
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"}
        )
        
        print(f"Login Status: {login_response.status_code}")
        if login_response.status_code != 200:
            print(f"❌ Login failed: {login_response.text}")
            return False
            
        token_data = login_response.json()
        access_token = token_data["access_token"]
        print(f"✅ Login successful")
        print(f"   Token Type: {token_data['token_type']}")
        print(f"   Access Token: {access_token[:20]}...")
        
        # Step 3: Check automatically created businesses
        print("\n3️⃣ STEP 3: Verify Automatic Business Creation")
        print("-" * 30)
        businesses_response = await client.get(
            f"{base_url}/businesses/my-businesses",
            headers={"Authorization": f"Bearer {access_token}"}
        )
        
        print(f"My Businesses Status: {businesses_response.status_code}")
        if businesses_response.status_code != 200:
            print(f"❌ Failed to fetch businesses: {businesses_response.text}")
            return False
            
        businesses = businesses_response.json()
        print(f"✅ Found {len(businesses)} business(es)")
        
        if len(businesses) == 0:
            print("❌ No businesses found - automatic creation failed")
            return False
        
        # Display detailed business information
        for i, business in enumerate(businesses, 1):
            print(f"\n   📋 Business #{i} Details:")
            print(f"      Name: {business['name']}")
            print(f"      Type: {business['business_type']}")
            print(f"      ID: {business['id']}")
            print(f"      Owner: {business.get('owner_name', 'N/A')}")
            print(f"      Phone: {business['phone_number']}")
            print(f"      Email: {business['email']}")
            print(f"      Status: {business['status']}")
            print(f"      Address: {business['address']['city']}, {business['address']['country']}")
            print(f"      POS Enabled: {business['settings']['pos']['enabled']}")
            print(f"      Is Online: {business['is_online']}")
        
        # Step 4: Test the frontend login flow (simulating what happens in the frontend)
        print("\n4️⃣ STEP 4: Simulate Frontend Login Flow")
        print("-" * 30)
        
        # This simulates what the frontend ApiService.getUserBusinesses() does
        print("   📡 Fetching user businesses (like frontend does)...")
        
        # The businesses we already fetched would be used by the frontend
        if businesses:
            business_data = businesses[0]  # Frontend takes the first business
            print(f"   ✅ Frontend would use business: {business_data['name']}")
            print(f"      Business ID: {business_data['id']}")
            print(f"      Business Type: {business_data['business_type']}")
            
            # This is what the frontend would create for the Business object
            frontend_business = {
                'id': business_data['id'],
                'name': business_data['name'],
                'email': business_data['email'],
                'phone': business_data['phone_number'],
                'address': business_data['address']['street'],
                'businessType': business_data['business_type']
            }
            print(f"   ✅ Frontend Business object created successfully")
        
        print("\n🎉 SUCCESS! Complete flow working perfectly:")
        print("   ✅ User registration creates user account")
        print("   ✅ Business automatically created during registration")
        print("   ✅ Login works with new user")
        print("   ✅ Business data available for frontend")
        print("   ✅ No more hardcoded business IDs!")
        
        return True


async def main():
    """Main test execution."""
    try:
        success = await test_complete_flow()
        if success:
            print(f"\n{'='*60}")
            print("🎊 ALL TESTS PASSED! 🎊")
            print("The registration flow now automatically creates businesses!")
            print("Users will always have at least one business after registration.")
            print(f"{'='*60}")
        else:
            print(f"\n{'='*60}")
            print("❌ TESTS FAILED!")
            print(f"{'='*60}")
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(main())
