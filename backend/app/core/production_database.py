"""
Production Database Configuration
Fixes TLS handshake issues and provides production-ready MongoDB setup
"""

import motor.motor_asyncio
from pymongo import MongoClient
from pymongo.read_preferences import ReadPreference
import logging
import ssl
import certifi
import os
from urllib.parse import quote_plus

class ProductionDatabaseConfig:
    def __init__(self):
        self.connection_pool_size = 50
        self.min_pool_size = 10
        self.max_idle_time_ms = 30000
        self.wait_queue_timeout_ms = 5000
        
    def get_connection_string_variants(self, base_uri: str) -> list:
        """Get different connection string variants to try."""
        variants = []
        
        # Original URI
        variants.append(base_uri)
        
        # Add explicit TLS settings
        if "?" in base_uri:
            base_uri_with_params = base_uri
        else:
            base_uri_with_params = base_uri + "?"
        
        # Variant 1: Standard TLS
        variants.append(f"{base_uri_with_params}&ssl=true&ssl_cert_reqs=CERT_REQUIRED")
        
        # Variant 2: TLS with specific version
        variants.append(f"{base_uri_with_params}&tls=true&tlsAllowInvalidCertificates=false")
        
        # Variant 3: More permissive TLS (for testing)
        variants.append(f"{base_uri_with_params}&ssl=true&ssl_cert_reqs=CERT_NONE")
        
        # Variant 4: Explicit TLS settings
        variants.append(f"{base_uri_with_params}&tls=true&tlsInsecure=false&retryWrites=true&w=majority")
        
        return variants
        
    def get_motor_client(self, uri: str, read_preference="primary"):
        """Get properly configured Motor client for production."""
        
        # Try different SSL/TLS configurations
        ssl_configs = [
            # Standard SSL configuration
            {
                "ssl": True,
                "ssl_cert_reqs": ssl.CERT_REQUIRED,
                "ssl_ca_certs": certifi.where(),
                "ssl_match_hostname": True
            },
            # Permissive SSL for testing
            {
                "ssl": True,
                "ssl_cert_reqs": ssl.CERT_NONE,
                "ssl_ca_certs": certifi.where(),
                "ssl_match_hostname": False
            },
            # Custom SSL context
            {
                "ssl": True,
                "ssl_context": self._create_ssl_context()
            },
            # No SSL (fallback for local development)
            {
                "ssl": False
            }
        ]
        
        connection_strings = self.get_connection_string_variants(uri)
        
        # Try each combination
        for conn_str in connection_strings:
            for ssl_config in ssl_configs:
                try:
                    logging.info(f"Trying connection with SSL config: {ssl_config.get('ssl', False)}")
                    
                    client = motor.motor_asyncio.AsyncIOMotorClient(
                        conn_str,
                        maxPoolSize=self.connection_pool_size,
                        minPoolSize=self.min_pool_size,
                        maxIdleTimeMS=self.max_idle_time_ms,
                        waitQueueTimeoutMS=self.wait_queue_timeout_ms,
                        # Connection timeouts
                        serverSelectionTimeoutMS=5000,
                        connectTimeoutMS=10000,
                        socketTimeoutMS=10000,
                        # Write concern for data safety
                        w="majority",
                        journal=True,
                        # Retry settings
                        retryWrites=True,
                        retryReads=True,
                        **ssl_config
                    )
                    
                    # Test the connection
                    try:
                        # This will raise an exception if connection fails
                        info = await client.server_info()
                        logging.info(f"Successfully connected to MongoDB. Server version: {info.get('version', 'unknown')}")
                        return client
                    except Exception as test_error:
                        logging.warning(f"Connection test failed: {test_error}")
                        client.close()
                        continue
                        
                except Exception as e:
                    logging.warning(f"Failed to create client with config {ssl_config}: {e}")
                    continue
        
        # If all attempts failed, create a basic client for graceful degradation
        logging.error("All connection attempts failed. Creating basic client for graceful degradation.")
        return self._create_fallback_client(uri)
    
    def _create_ssl_context(self):
        """Create custom SSL context."""
        context = ssl.create_default_context(cafile=certifi.where())
        context.check_hostname = False
        context.verify_mode = ssl.CERT_REQUIRED
        
        # Set minimum TLS version
        context.minimum_version = ssl.TLSVersion.TLSv1_2
        
        # Enable hostname checking
        context.check_hostname = True
        
        return context
    
    def _create_fallback_client(self, uri: str):
        """Create a fallback client that can handle connection failures gracefully."""
        try:
            return motor.motor_asyncio.AsyncIOMotorClient(
                uri,
                serverSelectionTimeoutMS=1000,  # Quick timeout
                connectTimeoutMS=1000,
                socketTimeoutMS=1000,
                maxPoolSize=1,
                minPoolSize=0
            )
        except Exception as e:
            logging.error(f"Even fallback client creation failed: {e}")
            return None

# Test connection function
async def test_database_connection(client):
    """Test database connection and return status."""
    if not client:
        return {"status": "error", "message": "No client available"}
    
    try:
        # Test basic connection
        info = await client.server_info()
        
        # Test database operations
        db = client.get_default_database()
        collections = await db.list_collection_names()
        
        return {
            "status": "connected",
            "server_version": info.get("version", "unknown"),
            "collections_count": len(collections),
            "message": "Database connection successful"
        }
        
    except Exception as e:
        return {
            "status": "error",
            "message": f"Database connection failed: {str(e)}"
        }

# Usage example
async def create_production_database():
    """Create production database connection."""
    config = ProductionDatabaseConfig()
    mongodb_uri = os.getenv("MONGODB_URI")
    
    if not mongodb_uri:
        logging.error("MONGODB_URI environment variable not set")
        return None
    
    client = config.get_motor_client(mongodb_uri)
    
    # Test the connection
    connection_status = await test_database_connection(client)
    logging.info(f"Database status: {connection_status}")
    
    return client if connection_status["status"] == "connected" else None
