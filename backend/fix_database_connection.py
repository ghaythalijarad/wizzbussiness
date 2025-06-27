#!/usr/bin/env python3
"""
Fix database connection with TLS bypass for development.
"""

import asyncio
import os
import sys
from dotenv import load_dotenv
import motor.motor_asyncio
import logging
import ssl

# Load environment variables
load_dotenv('.env')

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def test_connection_strategies():
    """Test different MongoDB connection strategies."""
    mongodb_uri = os.getenv("MONGO_URI")
    if not mongodb_uri:
        print("❌ MONGO_URI not found in environment variables")
        return None
        
    base_uri = mongodb_uri.split('?')[0]  # Remove existing query params
    
    strategies = [
        {
            "name": "TLS with relaxed certificates (Development)",
            "uri": f"{base_uri}?retryWrites=true&w=majority&tls=true&tlsAllowInvalidCertificates=true&tlsAllowInvalidHostnames=true"
        },
        {
            "name": "SSL disabled (Local testing only)",
            "uri": f"{base_uri}?retryWrites=true&w=majority&ssl=false"
        },
        {
            "name": "TLS insecure mode",
            "uri": f"{base_uri}?retryWrites=true&w=majority&tls=true&tlsInsecure=true"
        },
        {
            "name": "Standard SSL with cert bypass",
            "uri": f"{base_uri}?retryWrites=true&w=majority&ssl=true&ssl_cert_reqs=CERT_NONE"
        }
    ]
    
    for i, strategy in enumerate(strategies, 1):
        print(f"\n🔍 Strategy {i}: {strategy['name']}")
        print(f"   URI: {strategy['uri'][:80]}...")
        
        try:
            client = motor.motor_asyncio.AsyncIOMotorClient(
                strategy['uri'],
                serverSelectionTimeoutMS=5000,
                connectTimeoutMS=8000,
                socketTimeoutMS=8000,
            )
            
            # Test connection
            info = await client.server_info()
            print(f"   ✅ SUCCESS! Server version: {info.get('version', 'unknown')}")
            
            # Test database operations
            db = client.get_default_database()
            collections = await db.list_collection_names()
            print(f"   📁 Database: {db.name}")
            print(f"   📋 Collections: {len(collections)}")
            
            await client.close()
            
            print(f"\n🎉 WORKING CONNECTION FOUND!")
            print(f"💡 Update your .env file with:")
            print(f"MONGO_URI=\"{strategy['uri']}\"")
            
            return strategy['uri']
            
        except Exception as e:
            print(f"   ❌ Failed: {str(e)[:100]}...")
            continue
    
    print("\n❌ All connection strategies failed")
    return None

async def create_test_user_with_working_connection(working_uri):
    """Create test user with working connection."""
    try:
        from passlib.context import CryptContext
        
        client = motor.motor_asyncio.AsyncIOMotorClient(working_uri)
        db = client.get_default_database()
        users_collection = db["WB_users"]
        
        # Check if user exists
        existing_user = await users_collection.find_one({"email": "saif@yahoo.com"})
        if existing_user:
            print("✅ Test user already exists")
            print(f"👤 User details: {existing_user['email']}, Active: {existing_user.get('is_active', False)}")
            await client.close()
            return True
        
        # Create password hash
        pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        hashed_password = pwd_context.hash("Gha@551987")
        
        # Create test user
        test_user = {
            "email": "saif@yahoo.com",
            "hashed_password": hashed_password,
            "is_active": True,
            "is_superuser": False,
            "is_verified": True,
            "business_name": "Test Restaurant",
            "business_type": "restaurant",
            "phone_number": "+1234567890"
        }
        
        result = await users_collection.insert_one(test_user)
        print(f"✅ Created test user with ID: {result.inserted_id}")
        
        await client.close()
        return True
        
    except Exception as e:
        print(f"❌ Failed to create test user: {e}")
        return False

async def main():
    """Main function."""
    print("🚀 MongoDB TLS Connection Fix")
    print("=" * 50)
    
    working_uri = await test_connection_strategies()
    
    if working_uri:
        print(f"\n🔧 Testing user creation...")
        await create_test_user_with_working_connection(working_uri)
        
        print(f"\n📝 NEXT STEPS:")
        print(f"1. Update your .env file with the working URI")
        print(f"2. Restart your backend server")
        print(f"3. Test login again")
    else:
        print(f"\n💡 ALTERNATIVE SOLUTIONS:")
        print(f"1. Check MongoDB Atlas IP whitelist")
        print(f"2. Try recreating the database user")
        print(f"3. Check if cluster is paused/stopped")

if __name__ == "__main__":
    asyncio.run(main())
