"""
Production Application Configuration
Enhanced FastAPI application with Redis, improved database handling, and production features
"""

from fastapi import FastAPI, Request, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
import time
import logging
import os
from contextlib import asynccontextmanager
from datetime import datetime
import traceback

# Import services
from .services.redis_service import redis_service
from .core.production_database import create_production_database, test_database_connection
from .core.database import init_beanie

# Import controllers
from .controllers.order_controller import order_controller

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Global variables for services
database_client = None
service_status = {
    "database": {"connected": False, "error": None},
    "redis": {"connected": False, "error": None}
}

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events."""
    global database_client, service_status
    
    logger.info("Starting production application...")
    
    # Initialize database
    try:
        database_client = await create_production_database()
        if database_client:
            # Initialize Beanie with the production client
            await init_beanie(database_client)
            service_status["database"] = {"connected": True, "error": None}
            logger.info("Database initialized successfully")
        else:
            service_status["database"] = {"connected": False, "error": "Failed to create database client"}
            logger.warning("Database initialization failed - running in degraded mode")
    except Exception as e:
        service_status["database"] = {"connected": False, "error": str(e)}
        logger.error(f"Database initialization error: {e}")
    
    # Initialize Redis
    try:
        redis_connected = await redis_service.initialize()
        if redis_connected:
            service_status["redis"] = {"connected": True, "error": None}
            logger.info("Redis initialized successfully")
        else:
            service_status["redis"] = {"connected": False, "error": "Failed to connect to Redis"}
            logger.warning("Redis initialization failed - caching disabled")
    except Exception as e:
        service_status["redis"] = {"connected": False, "error": str(e)}
        logger.error(f"Redis initialization error: {e}")
    
    logger.info(f"Application started - Database: {service_status['database']['connected']}, Redis: {service_status['redis']['connected']}")
    
    yield
    
    # Shutdown
    logger.info("Shutting down application...")
    
    if redis_service:
        await redis_service.close()
    
    if database_client:
        database_client.close()
    
    logger.info("Application shutdown complete")

def create_production_app() -> FastAPI:
    """Create production-configured FastAPI application."""
    
    # Determine if running in production
    environment = os.getenv("ENVIRONMENT", "development")
    is_production = environment == "production"
    
    app = FastAPI(
        title="Order Receiver API - Production",
        description="Production-ready order management system with real-time notifications",
        version="2.0.0",
        docs_url="/docs" if not is_production else None,
        redoc_url="/redoc" if not is_production else None,
        lifespan=lifespan
    )
    
    # Security middleware
    allowed_hosts = ["*"]  # Configure this based on your domains
    if is_production:
        allowed_hosts = [
            "your-domain.com",
        ]

    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=allowed_hosts
    )
    
    # CORS configuration
    allowed_origins = ["*"]  # Configure this for production
    if is_production:
        allowed_origins = [
            "https://your-frontend-domain.com"  # Add your frontend URL
        ]

    app.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["*"],
    )
    
    # Request logging middleware
    @app.middleware("http")
    async def log_requests(request: Request, call_next):
        start_time = time.time()
        
        # Log request
        logger.info(f"Request: {request.method} {request.url}")
        
        try:
            response = await call_next(request)
            process_time = time.time() - start_time
            
            # Log response
            logger.info(
                f"Response: {request.method} {request.url} - "
                f"Status: {response.status_code} - "
                f"Time: {process_time:.3f}s"
            )
            
            # Add performance headers
            response.headers["X-Process-Time"] = str(process_time)
            
            return response
            
        except Exception as e:
            process_time = time.time() - start_time
            logger.error(
                f"Error: {request.method} {request.url} - "
                f"Error: {str(e)} - "
                f"Time: {process_time:.3f}s"
            )
            raise
    
    # Rate limiting middleware (simple version)
    @app.middleware("http")
    async def rate_limit_middleware(request: Request, call_next):
        """Basic rate limiting using Redis."""
        client_ip = request.client.host
        path = request.url.path
        
        # Skip rate limiting for health checks
        if path in ["/health", "/health/detailed"]:
            return await call_next(request)
        
        # Check rate limit if Redis is available
        if redis_service.connected:
            rate_key = f"rate_limit:{client_ip}"
            rate_check = await redis_service.check_rate_limit(rate_key, 100, 3600)  # 100 req/hour
            
            if not rate_check["allowed"]:
                return JSONResponse(
                    status_code=429,
                    content={
                        "error": "Rate limit exceeded",
                        "remaining": rate_check["remaining"],
                        "reset_time": rate_check["reset_time"]
                    }
                )
        
        return await call_next(request)
    
    # Error handling middleware
    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        """Global exception handler."""
        logger.error(f"Unhandled exception: {str(exc)}")
        logger.error(traceback.format_exc())
        
        if isinstance(exc, HTTPException):
            return JSONResponse(
                status_code=exc.status_code,
                content={"error": exc.detail}
            )
        
        # In production, don't expose internal errors
        if os.getenv("ENVIRONMENT") == "production":
            return JSONResponse(
                status_code=500,
                content={"error": "Internal server error"}
            )
        else:
            return JSONResponse(
                status_code=500,
                content={"error": str(exc)}
            )
    
    # Health check endpoints
    @app.get("/")
    async def root():
        """Root endpoint."""
        return {
            "message": "Order Receiver API - Production",
            "version": "2.0.0",
            "status": "running",
            "timestamp": datetime.utcnow().isoformat()
        }
    
    @app.get("/health")
    async def health_check():
        """Basic health check."""
        return {
            "status": "healthy",
            "timestamp": datetime.utcnow().isoformat(),
            "version": "2.0.0"
        }
    
    @app.get("/health/detailed")
    async def detailed_health():
        """Detailed health check with service status."""
        # Check database
        db_health = {"status": "unknown"}
        if database_client:
            db_health = await test_database_connection(database_client)
        elif service_status["database"]["error"]:
            db_health = {
                "status": "error",
                "message": service_status["database"]["error"]
            }
        
        # Check Redis
        redis_health = {"status": "not_configured"}
        if redis_service.connected:
            redis_health = await redis_service.health_check()
        elif service_status["redis"]["error"]:
            redis_health = {
                "status": "error", 
                "message": service_status["redis"]["error"]
            }
        
        # Overall health
        overall_healthy = (
            db_health.get("status") in ["connected", "unknown"] and
            redis_health.get("status") in ["connected", "not_configured"]
        )
        
        return {
            "status": "healthy" if overall_healthy else "degraded",
            "timestamp": datetime.utcnow().isoformat(),
            "services": {
                "database": db_health,
                "redis": redis_health
            },
            "environment": os.getenv("ENVIRONMENT", "development")
        }
    
    # Metrics endpoint
    @app.get("/metrics")
    async def metrics():
        """Application metrics endpoint."""
        return {
            "services": {
                "database": service_status["database"],
                "redis": service_status["redis"]
            },
            "environment": os.getenv("ENVIRONMENT", "development"),
            "timestamp": datetime.utcnow().isoformat()
        }
    
    # Include routers
    app.include_router(
        order_controller.router, 
        prefix="/api/v1", 
        tags=["orders"]
    )
    
    return app

# Create the app
app = create_production_app()

# Add startup message
@app.on_event("startup")
async def startup_message():
    """Log startup message."""
    logger.info("=== Order Receiver API - Production Started ===")
    logger.info(f"Environment: {os.getenv('ENVIRONMENT', 'development')}")
    logger.info(f"MongoDB URI configured: {'Yes' if os.getenv('MONGODB_URI') else 'No'}")
    logger.info(f"Redis URL configured: {'Yes' if os.getenv('REDIS_URL') else 'No'}")
    logger.info("=" * 50)
