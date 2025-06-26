#!/usr/bin/env python3
"""
Database Connection Test Script
Tests different MongoDB connection strategies to fix TLS issues
"""

import asyncio
import sys
import os
sys.path.append('backend')

from backend.app.core.production_database import ProductionDatabaseConfig, test_database_connection
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

async def test_mongodb_connection():
    """Test MongoDB connection with different strategies."""
    print("🔍 Testing MongoDB Connection Strategies...")
    print("=" * 50)
    
    # Load environment variables
    from dotenv import load_dotenv
    load_dotenv('backend/.env')
    
    mongodb_uri = os.getenv("MONGODB_URI") or os.getenv("MONGO_URI")
    if not mongodb_uri:
        print("❌ Neither MONGODB_URI nor MONGO_URI found in environment variables")
        return
    
    print(f"📡 Testing connection to: {mongodb_uri[:50]}...")
    print()
    
    config = ProductionDatabaseConfig()
    
    # Get connection string variants
    variants = config.get_connection_string_variants(mongodb_uri)
    
    for i, variant in enumerate(variants, 1):
        print(f"📋 Strategy {i}: Testing connection variant...")
        print(f"   Connection: {variant[:80]}...")
        
        try:
            client = config.get_motor_client(variant)
            if client:
                result = await test_database_connection(client)
                print(f"   Status: {result['status']}")
                print(f"   Message: {result['message']}")
                
                if result['status'] == 'connected':
                    print(f"   ✅ SUCCESS! Server version: {result.get('server_version', 'unknown')}")
                    print(f"   📊 Collections: {result.get('collections_count', 0)}")
                    client.close()
                    return variant
                else:
                    print(f"   ❌ Failed: {result['message']}")
                    if client:
                        client.close()
            else:
                print("   ❌ Failed to create client")
                
        except Exception as e:
            print(f"   ❌ Exception: {str(e)}")
        
        print()
    
    print("❌ All connection strategies failed")
    return None

if __name__ == "__main__":
    result = asyncio.run(test_mongodb_connection())
    
    if result:
        print("🎉 Found working connection strategy!")
        print(f"✅ Use this connection string: {result}")
    else:
        print("💡 Recommendations:")
        print("1. Check your MongoDB Atlas cluster is running")
        print("2. Verify IP whitelist includes 0.0.0.0/0 or Heroku IPs")
        print("3. Confirm username/password are correct")
        print("4. Try creating a new database user with simpler password")
