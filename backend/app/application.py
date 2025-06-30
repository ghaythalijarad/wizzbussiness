"""
Application factory using OOP principles - PostgreSQL Version.
"""
import logging
import os
from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .core.config import config
from .core.database import db_manager
from .controllers.health_controller import health_controller
from .controllers.auth_controller import auth_controller
from .controllers.business_controller import business_controller, admin_business_controller
from .controllers.item_controller import item_controller, category_controller
from .controllers.order_controller import order_controller
from .controllers.webhook_controller import webhook_controller
from .controllers.customer_tracking_controller import customer_tracking_controller
from .controllers.notification_controller import notification_ws_controller
from .controllers.pos_controller import pos_controller
from .controllers.centralized_platform_controller import centralized_platform_controller
from .services.auth_service import auth_service


def create_app() -> FastAPI:
    """Create and configure FastAPI application."""
    # Create FastAPI app
    app = FastAPI(
        title=config.title,
        version=config.version,
        debug=config.debug
    )
    
    # Configure static files
    uploads_dir = "uploads"
    if not os.path.exists(uploads_dir):
        os.makedirs(uploads_dir)
    app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")
    
    # Configure middleware
    @app.middleware("http")
    async def add_security_headers(request: Request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        return response
    
    # CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=config.cors.origins,
        allow_credentials=config.cors.allow_credentials,
        allow_methods=config.cors.allow_methods,
        allow_headers=config.cors.allow_headers,
    )
    
    # Configure events
    @app.on_event("startup")
    async def startup_event():
        """Initialize database and other services on startup."""
        try:
            # Initialize PostgreSQL database connection
            await db_manager.connect()
            logging.info("✅ PostgreSQL database connected successfully")
        except Exception as e:
            logging.error(f"⚠️ Database connection failed during startup: {e}")
            logging.warning("🚀 Continuing startup without database - health and simplified endpoints will still work")
    
    @app.on_event("shutdown")
    async def shutdown_event():
        """Cleanup on application shutdown."""
        try:
            await db_manager.disconnect()
            logging.info("Application shutdown completed successfully")
        except Exception as e:
            logging.error(f"Shutdown failed: {e}")
            raise

    # Configure routes
    # Health check routes
    app.include_router(
        health_controller.router,
        tags=["health"]
    )
    
    # Test authentication (for when database is not available)
    from .controllers.test_auth_controller import test_auth_router
    app.include_router(test_auth_router)
    
    # Authentication routes
    fastapi_users = auth_service.get_fastapi_users()
    auth_backend = auth_service.get_auth_backend()
    
    # FastAPI-Users auth routes
    app.include_router(
        fastapi_users.get_auth_router(auth_backend),
        prefix="/auth/jwt",
        tags=["auth"],
    )
    
    # Custom auth routes
    app.include_router(
        auth_controller.router,
        prefix="/auth",
        tags=["auth"],
    )
    
    # Password reset routes
    app.include_router(
        fastapi_users.get_reset_password_router(),
        prefix="/auth",
        tags=["auth"],
    )
    
    # Verification routes
    from .schemas.user import UserRead, UserUpdate
    app.include_router(
        fastapi_users.get_verify_router(UserRead),
        prefix="/auth",
        tags=["auth"],
    )
    
    # User management routes
    app.include_router(
        fastapi_users.get_users_router(UserRead, UserUpdate),
        prefix="/users",
        tags=["users"],
    )
    
    # Business routes
    app.include_router(
        business_controller.router,
        prefix="/businesses",
        tags=["businesses"],
    )
    
    # Admin business routes
    app.include_router(
        admin_business_controller.router,
        prefix="/admin/businesses",
        tags=["admin", "businesses"],
    )
    
    # Item management routes
    app.include_router(
        item_controller,
        tags=["items"],
    )
    
    # Category management routes
    app.include_router(
        category_controller,
        tags=["categories"],
    )
    
    # Order management routes
    app.include_router(
        order_controller.router,
        tags=["orders"],
    )
    
    # Webhook routes for centralized platform integration
    app.include_router(
        webhook_controller.router,
        tags=["webhooks"],
    )
    
    # Customer tracking routes
    app.include_router(
        customer_tracking_controller.router,
        tags=["customer-tracking"],
    )
    
    # Notification routes (WebSocket and HTTP)
    app.include_router(
        notification_ws_controller.router,
        prefix="/notifications",
        tags=["notifications"],
    )
    
    # POS Settings routes
    app.include_router(
        pos_controller.router,
        prefix="/api",
        tags=["pos"],
    )
    
    # Centralized Platform routes
    app.include_router(
        centralized_platform_controller,
        tags=["centralized-platform"],
    )

    # Configure logging
    logging.basicConfig(
        level=logging.INFO if not config.debug else logging.DEBUG,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    
    return app


# Create the app instance
app = create_app()
