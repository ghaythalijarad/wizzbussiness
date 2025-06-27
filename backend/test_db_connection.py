#!/usr/bin/env python3
"""
Test database connection and fix authentication issues.
"""

import asyncio
import os
import sys
from dotenv import load_dotenv
import motor.motor_asyncio
import logging

# Load environment variables
load_dotenv('.env')

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def test_database_connection():
    """Test MongoDB connection."""
    mongodb_uri = os.getenv("MONGO_URI")
    if not mongodb_uri:
        print("❌ MONGO_URI not found in environment variables")
        return False
        
    print(f"🔍 Testing connection to: {mongodb_uri[:50]}...")
    
    try:
        # Create client with basic configuration
        client = motor.motor_asyncio.AsyncIOMotorClient(
            mongodb_uri,
            serverSelectionTimeoutMS=5000,
            connectTimeoutMS=10000,
            socketTimeoutMS=10000,
        )
        
        # Test connection
        info = await client.server_info()
        print(f"✅ Successfully connected to MongoDB")
        print(f"📊 Server version: {info.get('version', 'unknown')}")
        
        # Test database access
        db = client.get_default_database()
        collections = await db.list_collection_names()
        print(f"📁 Database: {db.name}")
        print(f"📋 Collections found: {len(collections)}")
        
        # Test user collection specifically
        if "WB_users" in collections:
            users_collection = db["WB_users"]
            user_count = await users_collection.count_documents({})
            print(f"👥 Users in WB_users collection: {user_count}")
            
            # Try to find the test user
            test_user = await users_collection.find_one({"email": "saif@yahoo.com"})
            if test_user:
                print(f"🔍 Found test user: {test_user['email']}")
                print(f"✅ User is active: {test_user.get('is_active', False)}")
            else:
                print("⚠️ Test user saif@yahoo.com not found in database")
        else:
            print("⚠️ WB_users collection not found")
        
        await client.close()
        return True
        
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False

async def create_test_user():
    """Create a test user if it doesn't exist."""
    mongodb_uri = os.getenv("MONGO_URI")
    if not mongodb_uri:
        print("❌ MONGO_URI not found")
        return False
        
    try:
        from passlib.context import CryptContext
        
        client = motor.motor_asyncio.AsyncIOMotorClient(mongodb_uri)
        db = client.get_default_database()
        users_collection = db["WB_users"]
        
        # Check if user exists
        existing_user = await users_collection.find_one({"email": "saif@yahoo.com"})
        if existing_user:
            print("✅ Test user already exists")
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
    """Main test function."""
    print("🚀 Database Connection Test")
    print("=" * 50)
    
    # Test connection
    connected = await test_database_connection()
    if not connected:
        print("💡 Try these solutions:")
        print("1. Check MongoDB Atlas cluster is running")
        print("2. Verify IP whitelist includes your IP")
        print("3. Confirm username/password are correct")
        return
    
    print("\n🔧 Creating test user if needed...")
    await create_test_user()
    
    print("\n✅ Database test completed!")

if __name__ == "__main__":
    asyncio.run(main())
