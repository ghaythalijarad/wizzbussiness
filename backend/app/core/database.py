"""
Database connection and management using OOP principles.
"""
import motor.motor_asyncio
from beanie import init_beanie
from typing import Optional
import logging
import ssl
import os
from app.core.config import config
import certifi  # add CA file for Atlas TLS validation

logger = logging.getLogger(__name__)


class DatabaseManager:
    """Database connection and management class."""
    
    def __init__(self):
        self._client: Optional[motor.motor_asyncio.AsyncIOMotorClient] = None
        self._database = None
    
    async def connect(self) -> None:
        """Establish database connection optimized for Heroku deployment with TLS fallback."""
        atlas_uri = config.database.mongo_uri
        
        # Check if TLS_INSECURE is set in environment for Heroku
        tls_insecure = os.getenv('TLS_INSECURE', 'false').lower() == 'true'
        
        # Try multiple connection strategies optimized for Heroku
        connection_strategies = []
        
        if tls_insecure:
            # Strategy for Heroku with relaxed TLS
            connection_strategies.append({
                "name": "Insecure TLS for Heroku",
                "config": {
                    "tls": True,
                    "tlsInsecure": True,
                    "serverSelectionTimeoutMS": 5000,
                    "connectTimeoutMS": 10000,
                    "socketTimeoutMS": 10000,
                    "retryWrites": True,
                    "maxPoolSize": 1
                }
            })
        
        connection_strategies.extend([
            {
                "name": "Aggressive TLS bypass for development",
                "config": {
                    "tls": True,
                    "tlsInsecure": True,
                    "tlsAllowInvalidCertificates": True,
                    "tlsAllowInvalidHostnames": True,
                    "serverSelectionTimeoutMS": 3000,
                    "connectTimeoutMS": 8000,
                    "socketTimeoutMS": 8000,
                    "retryWrites": True,
                    "maxPoolSize": 1
                }
            },
            {
                "name": "TLS with relaxed verification",
                "config": {
                    "tls": True,
                    "tlsAllowInvalidCertificates": True,
                    "tlsAllowInvalidHostnames": True,
                    "serverSelectionTimeoutMS": 5000,
                    "connectTimeoutMS": 10000,
                    "socketTimeoutMS": 10000,
                    "retryWrites": True,
                    "w": 'majority',
                    "maxPoolSize": 1
                }
            },
            {
                "name": "Standard TLS with certifi",
                "config": {
                    "tls": True,
                    "tlsCAFile": certifi.where(),
                    "serverSelectionTimeoutMS": 8000,
                    "connectTimeoutMS": 12000,
                    "socketTimeoutMS": 12000,
                    "retryWrites": True,
                    "w": 'majority',
                    "maxPoolSize": 1
                }
            },
            {
                "name": "Basic connection with timeout",
                "config": {
                    "serverSelectionTimeoutMS": 3000,
                    "connectTimeoutMS": 5000,
                    "socketTimeoutMS": 5000,
                    "retryWrites": True,
                    "maxPoolSize": 1
                }
            }
        ])
        
        for strategy in connection_strategies:
            try:
                logger.info(f"Attempting to connect to MongoDB Atlas using: {strategy['name']}")
                
                self._client = motor.motor_asyncio.AsyncIOMotorClient(
                    atlas_uri,
                    **strategy['config']
                )
                
                # Test the connection with a ping
                await self._client.admin.command('ping')
                self._database = self._client.get_default_database()
                logger.info(f"✅ Successfully connected to MongoDB Atlas with: {strategy['name']}")
                return
                
            except Exception as e:
                logger.error(f"❌ {strategy['name']} failed: {e}")
                if self._client:
                    self._client.close()
                    self._client = None
                continue
        
        # If all strategies failed, try one more time with a completely minimal config
        try:
            logger.info("Final attempt: minimal configuration")
            self._client = motor.motor_asyncio.AsyncIOMotorClient(atlas_uri)
            await self._client.admin.command('ping')
            self._database = self._client.get_default_database()
            logger.info("✅ Successfully connected with minimal configuration")
            return
        except Exception as e:
            logger.error(f"❌ Final attempt failed: {e}")
            if self._client:
                self._client.close()
                self._client = None
        
        # If all strategies failed
        logger.error("All MongoDB connection strategies failed")
        raise Exception("Database connection failed: All connection strategies exhausted")
    
    async def disconnect(self) -> None:
        """Close database connection."""
        if self._client:
            self._client.close()
            logger.info("Disconnected from MongoDB")
    
    async def initialize_beanie(self, document_models: list) -> None:
        """Initialize Beanie ODM with document models."""
        if self._database is None:
            raise RuntimeError("Database connection not established")
        
        try:
            await init_beanie(database=self._database, document_models=document_models)
            logger.info("Beanie ODM initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize Beanie: {e}")
            raise
    
    async def test_connection(self) -> dict:
        """Test database connection and return status."""
        try:
            if self._client is None:
                return {"status": "error", "message": "No database connection"}
            
            # Test connection with ping
            await self._client.admin.command("ping")
            
            if self._database is not None:
                return {
                    "status": "connected",
                    "database": self._database.name,
                    "server_info": "Connected successfully"
                }
            else:
                return {"status": "error", "message": "Database not initialized"}
        except Exception as e:
            return {"status": "error", "message": str(e)}
    
    @property
    def client(self) -> motor.motor_asyncio.AsyncIOMotorClient:
        """Get the MongoDB client."""
        if self._client is None:
            raise RuntimeError("Database connection not established")
        return self._client
    
    @property
    def database(self):
        """Get the database instance."""
        if self._database is None:
            raise RuntimeError("Database connection not established")
        return self._database


# Global database manager instance
db_manager = DatabaseManager()
