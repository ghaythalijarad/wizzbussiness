#!/usr/bin/env python3
"""
Quick script to check users in the database
"""
import asyncio
import motor.motor_asyncio
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

async def check_users():
    """Check what users exist in the database"""
    
    print("🚀 Starting user check script...")
    
    # Get MongoDB URI from environment
    mongodb_uri = os.getenv("MONGO_URI")
    print(f"📍 MongoDB URI found: {mongodb_uri is not None}")
    if not mongodb_uri:
        print("❌ MONGO_URI not found in environment")
        return
    
    print(f"🔍 Connecting to MongoDB...")
    
    try:
        client = motor.motor_asyncio.AsyncIOMotorClient(mongodb_uri, serverSelectionTimeoutMS=5000)
        db = client.get_database("Wizz_central_DB")
        users_collection = db.get_collection("WB_users")
        
        # Get all users
        users = await users_collection.find({}).to_list(length=None)
        
        print(f"📊 Found {len(users)} users in database:")
        print("=" * 50)
        
        for user in users:
            print(f"📧 Email: {user.get('email')}")
            print(f"🆔 ID: {user.get('_id')}")
            print(f"✅ Active: {user.get('is_active', False)}")
            print(f"🔒 Verified: {user.get('is_verified', False)}")
            print(f"📱 Phone: {user.get('phone_number', 'N/A')}")
            print(f"🏢 Business: {user.get('business_name', 'N/A')}")
            print("-" * 30)
        
        client.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(check_users())
