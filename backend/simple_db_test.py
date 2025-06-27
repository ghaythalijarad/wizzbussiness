#!/usr/bin/env python3
"""
Simple database test with different connection strings.
"""

import asyncio
import motor.motor_asyncio
import os
from dotenv import load_dotenv

load_dotenv('.env')

async def test_simple_connection():
    """Test simple connection."""
    
    # Get base URI without query params
    original_uri = os.getenv("MONGO_URI")
    base_uri = original_uri.split('?')[0]
    
    # Test different connection strings
    test_uris = [
        f"{base_uri}?ssl=false",  # No SSL at all
        f"{base_uri}?retryWrites=true&w=majority&tls=true&tlsInsecure=true",  # TLS insecure
        f"{base_uri}?retryWrites=true&w=majority&ssl=true&ssl_cert_reqs=CERT_NONE",  # SSL bypass
    ]
    
    for i, uri in enumerate(test_uris, 1):
        print(f"\n🔍 Test {i}: {uri[:80]}...")
        
        try:
            client = motor.motor_asyncio.AsyncIOMotorClient(
                uri,
                serverSelectionTimeoutMS=3000,
                connectTimeoutMS=5000,
                socketTimeoutMS=5000,
            )
            
            # Test connection
            await client.server_info()
            print(f"   ✅ SUCCESS!")
            
            # Test database operations
            db = client.get_default_database()
            collections = await db.list_collection_names()
            print(f"   📁 Database: {db.name}, Collections: {len(collections)}")
            
            # Update .env file
            with open('.env', 'r') as f:
                content = f.read()
            
            new_content = content.replace(original_uri, uri)
            
            with open('.env', 'w') as f:
                f.write(new_content)
                
            print(f"   💾 Updated .env file with working URI")
            
            await client.close()
            return True
            
        except Exception as e:
            print(f"   ❌ Failed: {str(e)[:80]}...")
            continue
    
    print("\n❌ All tests failed")
    return False

if __name__ == "__main__":
    asyncio.run(test_simple_connection())
