#!/usr/bin/env python3
"""
Direct login test without database dependencies
"""
import httpx
import asyncio

BASE_URL = "http://localhost:8000"

async def test_login_direct():
    """Test direct login with specific credentials"""
    
    print("🔐 Testing Direct Login with Credentials")
    print("=" * 50)
    
    # Test credentials
    test_credentials = {
        "username": "saif@yahoo.com",
        "password": "Gha@551987"
    }
    
    async with httpx.AsyncClient() as client:
        # First test the working test endpoint
        print("🧪 Testing WORKING test authentication endpoint:")
        print(f"📍 Endpoint: {BASE_URL}/test-auth/login")
        print(f"📧 Email: {test_credentials['username']}")
        print(f"🔑 Password: {'*' * len(test_credentials['password'])}")
        print()
        
        try:
            response = await client.post(
                f"{BASE_URL}/test-auth/login",
                data=test_credentials,
                headers={"Content-Type": "application/x-www-form-urlencoded"}
            )
            
            print(f"📊 Response Status: {response.status_code}")
            if response.status_code == 200:
                token_data = response.json()
                print(f"✅ Test authentication successful!")
                print(f"🎫 Access Token: {token_data.get('access_token', 'Not found')[:50]}...")
                print(f"🏷️  Token Type: {token_data.get('token_type', 'Not found')}")
                print(f"🧪 Test Mode: {token_data.get('test_mode', False)}")
                print(f"💬 Message: {token_data.get('message', 'No message')}")
                test_success = True
            else:
                print(f"❌ Test authentication failed with status {response.status_code}")
                test_success = False
                
        except Exception as e:
            print(f"💥 Exception during test login: {e}")
            test_success = False
        
        print()
        print("🚫 Testing BROKEN main authentication endpoint (for comparison):")
        print(f"📍 Endpoint: {BASE_URL}/auth/jwt/login")
        print()
        
        try:
            response = await client.post(
                f"{BASE_URL}/auth/jwt/login",
                data=test_credentials,
                headers={"Content-Type": "application/x-www-form-urlencoded"}
            )
            
            print(f"📊 Response Status: {response.status_code}")
            if response.status_code == 200:
                token_data = response.json()
                print(f"✅ Main authentication successful!")
                print(f"🎫 Access Token: {token_data.get('access_token', 'Not found')}")
                print(f"🏷️  Token Type: {token_data.get('token_type', 'Not found')}")
                main_success = True
            else:
                print(f"❌ Main authentication failed with status {response.status_code}")
                print(f"📄 Error: {response.text[:200]}...")
                main_success = False
                
        except Exception as e:
            print(f"💥 Exception during main login: {e}")
            main_success = False
        
        return test_success

async def test_health_check():
    """Test if server is running"""
    print("🏥 Testing Health Check")
    print("=" * 30)
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(f"{BASE_URL}/health")
            print(f"📊 Health Status: {response.status_code}")
            print(f"📄 Health Response: {response.text}")
            return response.status_code == 200
        except Exception as e:
            print(f"💥 Health check failed: {e}")
            return False

async def main():
    """Main test function"""
    print("🚀 Direct Login Test Suite")
    print("=" * 60)
    
    # Test health first
    health_ok = await test_health_check()
    if not health_ok:
        print("❌ Server not responding to health checks")
        return
    
    print()
    
    # Test login
    login_ok = await test_login_direct()
    
    print()
    print("📋 Test Summary:")
    print(f"   Health Check: {'✅ PASS' if health_ok else '❌ FAIL'}")
    print(f"   Login Test:   {'✅ PASS' if login_ok else '❌ FAIL'}")

if __name__ == "__main__":
    asyncio.run(main())
