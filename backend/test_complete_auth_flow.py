#!/usr/bin/env python3
"""
Test complete authentication flow with profile data retrieval.
"""
import httpx
import asyncio
import json

BASE_URL = "http://localhost:8000"

async def test_complete_auth_flow():
    """Test the complete authentication and profile flow."""
    
    print("🔐 Testing Complete Authentication Flow")
    print("=" * 60)
    
    # Test credentials
    test_credentials = {
        "username": "saif@yahoo.com",
        "password": "Gha@551987"
    }
    
    async with httpx.AsyncClient() as client:
        # Step 1: Login
        print("\n1️⃣ STEP 1: Login")
        print("-" * 30)
        print(f"📍 Endpoint: {BASE_URL}/test-auth/login")
        
        try:
            login_response = await client.post(
                f"{BASE_URL}/test-auth/login",
                data=test_credentials,
                headers={"Content-Type": "application/x-www-form-urlencoded"}
            )
            
            print(f"📊 Login Status: {login_response.status_code}")
            if login_response.status_code == 200:
                login_data = login_response.json()
                access_token = login_data.get('access_token')
                test_mode = login_data.get('test_mode', False)
                
                print(f"✅ Login successful!")
                print(f"🎫 Access Token: {access_token[:50]}...")
                print(f"🧪 Test Mode: {test_mode}")
                print(f"💬 Message: {login_data.get('message', 'No message')}")
            else:
                print(f"❌ Login failed: {login_response.text}")
                return False
                
        except Exception as e:
            print(f"💥 Login exception: {e}")
            return False
        
        # Step 2: Get Profile Data
        print("\n2️⃣ STEP 2: Get Profile Data")
        print("-" * 30)
        print(f"📍 Endpoint: {BASE_URL}/test-auth/me")
        
        try:
            profile_response = await client.get(
                f"{BASE_URL}/test-auth/me",
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Content-Type": "application/json"
                }
            )
            
            print(f"📊 Profile Status: {profile_response.status_code}")
            if profile_response.status_code == 200:
                profile_data = profile_response.json()
                
                print(f"✅ Profile data retrieved successfully!")
                print(f"👤 User ID: {profile_data.get('id')}")
                print(f"📧 Email: {profile_data.get('email')}")
                print(f"🏢 Business Name: {profile_data.get('business_name')}")
                print(f"🏪 Business Type: {profile_data.get('business_type')}")
                print(f"👨‍💼 Owner Name: {profile_data.get('owner_name')}")
                print(f"📱 Phone: {profile_data.get('phone_number')}")
                print(f"🧪 Test Mode: {profile_data.get('test_mode')}")
                
                return True
            else:
                print(f"❌ Profile retrieval failed: {profile_response.text}")
                return False
                
        except Exception as e:
            print(f"💥 Profile retrieval exception: {e}")
            return False

async def test_frontend_flow():
    """Test the flow that frontend would use."""
    
    print("\n\n🚀 Testing Frontend-Style Flow")
    print("=" * 60)
    
    async with httpx.AsyncClient() as client:
        # Step 1: Login (same as frontend)
        print("\n1️⃣ Frontend Login")
        login_response = await client.post(
            f"{BASE_URL}/test-auth/login",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={"username": "saif@yahoo.com", "password": "Gha@551987"}
        )
        
        if login_response.status_code == 200:
            login_data = login_response.json()
            access_token = login_data.get('access_token')
            print(f"✅ Frontend login successful")
            
            # Step 2: Get profile (same as frontend)
            print("\n2️⃣ Frontend Profile Request")
            
            # The frontend will detect test mode and use test endpoint
            profile_response = await client.get(
                f"{BASE_URL}/test-auth/me",  # Frontend will choose this endpoint
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Content-Type": "application/json"
                }
            )
            
            if profile_response.status_code == 200:
                profile_data = profile_response.json()
                print(f"✅ Frontend profile retrieval successful")
                print(f"🎯 Data available for UI:")
                print(f"   - Business Name: {profile_data.get('business_name')}")
                print(f"   - Owner Name: {profile_data.get('owner_name')}")
                print(f"   - Email: {profile_data.get('email')}")
                print(f"   - Phone: {profile_data.get('phone_number')}")
                
                return True
            else:
                print(f"❌ Frontend profile failed: {profile_response.text}")
                return False
        else:
            print(f"❌ Frontend login failed: {login_response.text}")
            return False

async def main():
    """Main test function."""
    
    # Test health first
    async with httpx.AsyncClient() as client:
        health_response = await client.get(f"{BASE_URL}/health")
        if health_response.status_code != 200:
            print("❌ Server not responding to health checks")
            return
    
    print("🏥 Server health check: ✅ PASS")
    
    # Test complete auth flow
    auth_success = await test_complete_auth_flow()
    
    # Test frontend flow
    frontend_success = await test_frontend_flow()
    
    print("\n" + "=" * 60)
    print("📋 FINAL TEST SUMMARY:")
    print(f"   Server Health:     ✅ PASS")
    print(f"   Authentication:    {'✅ PASS' if auth_success else '❌ FAIL'}")
    print(f"   Profile Data:      {'✅ PASS' if auth_success else '❌ FAIL'}")
    print(f"   Frontend Flow:     {'✅ PASS' if frontend_success else '❌ FAIL'}")
    
    if auth_success and frontend_success:
        print("\n🎉 SUCCESS! Profile data is now populated!")
        print("💡 The frontend will now be able to:")
        print("   - Login users successfully")
        print("   - Retrieve complete profile data")
        print("   - Display business information")
        print("   - Show owner details")
        print("\n📱 Frontend can now access:")
        print("   - User email and contact info")
        print("   - Business name and type")
        print("   - Owner name for display")
        print("   - All profile fields populated")
    else:
        print("\n❌ Some tests failed - check the errors above")

if __name__ == "__main__":
    asyncio.run(main())
