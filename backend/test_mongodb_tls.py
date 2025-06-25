"""
MongoDB Atlas TLS bypass test for Heroku deployment.
This is a temporary workaround to test database connectivity.
"""
import motor.motor_asyncio
import asyncio
import ssl
from app.core.config import config


async def test_mongodb_connection():
    """Test MongoDB connection with different SSL configurations."""
    atlas_uri = config.database.mongo_uri
    
    print("Testing MongoDB Atlas connection...")
    
    # Test 1: Standard connection with TLS verification
    try:
        print("Test 1: Standard TLS connection...")
        client = motor.motor_asyncio.AsyncIOMotorClient(
            atlas_uri,
            tls=True,
            serverSelectionTimeoutMS=5000
        )
        await client.admin.command('ping')
        print("✅ Standard TLS connection successful!")
        client.close()
    except Exception as e:
        print(f"❌ Standard TLS failed: {e}")
    
    # Test 2: TLS without certificate verification (TEMPORARY)
    try:
        print("Test 2: TLS without cert verification...")
        ssl_context = ssl.create_default_context()
        ssl_context.check_hostname = False
        ssl_context.verify_mode = ssl.CERT_NONE
        
        client = motor.motor_asyncio.AsyncIOMotorClient(
            atlas_uri,
            tls=True,
            tlsAllowInvalidCertificates=True,
            tlsAllowInvalidHostnames=True,
            serverSelectionTimeoutMS=5000
        )
        await client.admin.command('ping')
        print("✅ TLS without cert verification successful!")
        client.close()
    except Exception as e:
        print(f"❌ TLS without cert verification failed: {e}")
    
    # Test 3: Direct connection without TLS
    try:
        print("Test 3: Connection without TLS...")
        # Convert srv to standard connection
        uri_without_tls = atlas_uri.replace('mongodb+srv://', 'mongodb://').replace('?retryWrites=true&w=majority', '')
        client = motor.motor_asyncio.AsyncIOMotorClient(
            uri_without_tls,
            serverSelectionTimeoutMS=5000
        )
        await client.admin.command('ping')
        print("✅ Connection without TLS successful!")
        client.close()
    except Exception as e:
        print(f"❌ Connection without TLS failed: {e}")


if __name__ == "__main__":
    asyncio.run(test_mongodb_connection())
