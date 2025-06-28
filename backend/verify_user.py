#!/usr/bin/env python3
"""
Script to manually verify a user for testing
"""
import asyncio
import motor.motor_asyncio
from dotenv import load_dotenv
import os
import sys

# Load environment variables
load_dotenv()

async def verify_user(email):
    """Manually verify a user"""
    
    print(f"🚀 Starting verification for {email}...")
    
    # Get MongoDB URI from environment
    mongodb_uri = os.getenv("MONGO_URI")
    if not mongodb_uri:
        print("❌ MONGO_URI not found in environment")
        return
    
    try:
        client = motor.motor_asyncio.AsyncIOMotorClient(mongodb_uri, serverSelectionTimeoutMS=5000)
        db = client.get_database("Wizz_central_DB")
        users_collection = db.get_collection("WB_users")
        
        # Find and update the user
        result = await users_collection.update_one(
            {"email": email},
            {"$set": {"is_verified": True}}
        )
        
        if result.matched_count > 0:
            print(f"✅ User {email} has been verified successfully!")
            
            # Verify the update
            user = await users_collection.find_one({"email": email})
            print(f"🔒 Verification status: {user.get('is_verified', False)}")
        else:
            print(f"❌ User {email} not found in database")
        
        client.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    print("🔧 Script starting...")
    if len(sys.argv) != 2:
        print("Usage: python3 verify_user.py <email>")
        sys.exit(1)
    
    email = sys.argv[1]
    print(f"📧 Verifying email: {email}")
    asyncio.run(verify_user(email))
