"""
Database connection and management using OOP principles.
"""
import motor.motor_asyncio
from beanie import init_beanie
from typing import Optional
import logging
from app.core.config import config

logger = logging.getLogger(__name__)


class DatabaseManager:
    """Database connection and management class."""
    
    def __init__(self):
        self._client: Optional[motor.motor_asyncio.AsyncIOMotorClient] = None
        self._database = None
    
    async def connect(self) -> None:
        """Establish database connection with optimized settings for Heroku."""
        atlas_uri = config.database.mongo_uri
        
        # Try MongoDB Atlas with optimized settings for Heroku
        try:
            logger.info("Attempting to connect to MongoDB Atlas...")
            self._client = motor.motor_asyncio.AsyncIOMotorClient(
                atlas_uri,
                serverSelectionTimeoutMS=10000,  # Reduced timeout for Heroku
                connectTimeoutMS=10000,
                socketTimeoutMS=10000,
                tlsAllowInvalidCertificates=True,
                tlsAllowInvalidHostnames=True,
                retryWrites=True,
                w='majority'
            )
            
            # Test the connection with shorter timeout
            await self._client.admin.command('ping')
            self._database = self._client.get_default_database()
            logger.info("✅ Successfully connected to MongoDB Atlas")
            return
            
        except Exception as e:
            logger.error(f"MongoDB Atlas connection failed: {e}")
            if self._client:
                self._client.close()
                self._client = None
            
            # For Heroku deployment, we need Atlas to work - no local fallback
            raise Exception(f"Database connection failed: {e}")
        try:
            logger.info("Falling back to local MongoDB...")
            self._client = motor.motor_asyncio.AsyncIOMotorClient(
                local_uri,
                serverSelectionTimeoutMS=30000,
                connectTimeoutMS=30000,
                socketTimeoutMS=30000,
            )
            
            # Test the connection
            await self._client.admin.command('ping')
            self._database = self._client.get_default_database()
            logger.info("✅ Successfully connected to local MongoDB")
            return
            
        except Exception as local_error:
            logger.error(f"Local MongoDB connection failed: {local_error}")
            raise Exception(f"Failed to connect to both Atlas and local MongoDB. Atlas: {atlas_error}, Local: {local_error}")
    
    async def disconnect(self) -> None:
        """Close database connection."""
        if self._client:
            self._client.close()
            logger.info("Disconnected from MongoDB")
    
    async def initialize_beanie(self, document_models: list) -> None:
        """Initialize Beanie ODM with document models."""
        if not self._database:
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
