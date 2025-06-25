"""
Health check controller using OOP principles.
"""
from fastapi import APIRouter, Request
from ..core.database import db_manager
from ..core.config import config


class HealthController:
    """Health check controller class."""
    
    def __init__(self):
        self.router = APIRouter()
        self._setup_routes()
    
    def _setup_routes(self):
        """Setup health check routes."""
        
        @self.router.get("/")
        async def root():
            """Root endpoint."""
            return {
                "message": "Order Receiver API",
                "version": config.version,
                "title": config.title
            }
        
        @self.router.get("/health")
        async def health_check():
            """Basic health check."""
            return {"status": "healthy", "timestamp": "2025-06-25", "service": "Order Receiver API"}
        
        @self.router.get("/health/detailed")
        async def detailed_health_check():
            """Detailed health check including database status."""
            try:
                db_status = await db_manager.test_connection()
                return {
                    "status": "healthy",
                    "timestamp": "2025-06-25",
                    "service": "Order Receiver API",
                    "version": config.version,
                    "database": db_status,
                    "environment": "production" if not config.debug else "development"
                }
            except Exception as e:
                return {
                    "status": "healthy",
                    "timestamp": "2025-06-25", 
                    "service": "Order Receiver API",
                    "version": config.version,
                    "database": {"status": "error", "message": "No database connection"},
                    "environment": "production" if not config.debug else "development",
                    "note": "API is running without database"
                }
        
        @self.router.get("/test-mongo")
        async def test_mongo(request: Request):
            """MongoDB connection test."""
            return await db_manager.test_connection()


# Create controller instance
health_controller = HealthController()
