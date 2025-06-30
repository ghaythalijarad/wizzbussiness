"""
Health check controller using OOP principles.
"""
from fastapi import APIRouter, Request, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from ..core.db_manager import get_async_session
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
        async def health_check(session: AsyncSession = Depends(get_async_session)):
            """Basic health check."""
            try:
                await session.execute("SELECT 1")
                return {"status": "healthy", "timestamp": "2025-06-25", "service": "Order Receiver API"}
            except Exception as e:
                return {"status": "error", "detail": str(e)}
        
        @self.router.get("/health/detailed")
        async def detailed_health_check(session: AsyncSession = Depends(get_async_session)):
            """Detailed health check including database status."""
            try:
                await session.execute("SELECT 1")
                db_status = {"status": "up"}
            except Exception:
                db_status = {"status": "down", "message": "No database connection"}
            
            return {
                "status": "healthy",
                "timestamp": "2025-06-25",
                "service": "Order Receiver API",
                "version": config.version,
                "database": db_status,
                "environment": "production" if not config.debug else "development"
            }
        
        @self.router.get("/test-mongo")
        async def test_mongo(request: Request):
            """MongoDB connection test."""
            return await db_manager.test_connection()


# Create controller instance
health_controller = HealthController()
