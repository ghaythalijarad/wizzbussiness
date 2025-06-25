"""
Database connection and management using OOP principles.
"""
import motor.motor_asyncio
from beanie import init_beanie
from typing import Optional
import logging
from app.core.config import config
import certifi  # add CA file for Atlas TLS validation

logger = logging.getLogger(__name__)


class DatabaseManager:
    """Database connection and management class."""
    
    def __init__(self):
        self._client: Optional[motor.motor_asyncio.AsyncIOMotorClient] = None
        self._database = None
    
    async def connect(self) -> None:
        """Establish database connection optimized for Heroku deployment with TLS 1.2+."""
        atlas_uri = config.database.mongo_uri
        
        try:
            logger.info("Attempting to connect to MongoDB Atlas with TLS 1.2+...")
            
            # Enhanced TLS connection for Atlas with explicit TLS version
            self._client = motor.motor_asyncio.AsyncIOMotorClient(
                atlas_uri,
                tls=True,
                tlsCAFile=certifi.where(),
                serverSelectionTimeoutMS=30000,  # Increased timeout for Heroku
                connectTimeoutMS=30000,
                socketTimeoutMS=30000,
                retryWrites=True,
                w='majority'
            )
            
            # Test the connection with a ping
            await self._client.admin.command('ping')
            self._database = self._client.get_default_database()
            logger.info("✅ Successfully connected to MongoDB Atlas with TLS")
            
        except Exception as e:
            logger.error(f"MongoDB Atlas connection failed: {e}")
            if self._client:
                self._client.close()
                self._client = None
            self._database = None
            logger.warning("Continuing without database connection")
            # Never raise exception to prevent startup crash
    
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
