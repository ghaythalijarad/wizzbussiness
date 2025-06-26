"""
Application factory using OOP principles - Clean Version.
"""
import logging
import os
from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from beanie import init_beanie

from .core.config import config
from .core.database import db_manager
from .models.user import User
from .models.business import Business, Restaurant, Store, Pharmacy, Kitchen
from .models.item import Item, ItemCategory
from .models.order import Order
from .models.pos_settings import BusinessPosSettings, PosOrderSyncLog
from .services.simple_notification_service import SimpleNotification
from .controllers.health_controller import health_controller
from .controllers.auth_controller import auth_controller
from .controllers.business_controller import business_controller, admin_business_controller
from .controllers.item_controller import item_controller, category_controller
from .controllers.order_controller import order_controller
from .controllers.webhook_controller import webhook_controller
from .controllers.customer_tracking_controller import customer_tracking_controller
from .controllers.notification_controller import notification_ws_controller
from .controllers.simple_notification_controller import simple_notification_controller
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
            # Initialize database connection (non-blocking)
            await db_manager.connect()
            if db_manager._client:
                logging.info("Database connected successfully")
                # Drop any conflicting index
                db = db_manager.database
                users_coll = db.get_collection("WB_users")
                try:
                    await users_coll.drop_index("unique_email_idx")
                except Exception:
                    pass
                # Initialize Beanie ODM
                await init_beanie(database=db, document_models=[User, Business, Restaurant, Store, Pharmacy, Kitchen, Item, ItemCategory, Order, BusinessPosSettings, PosOrderSyncLog, SimpleNotification])
                logging.info("✅ Application startup completed with database")
            else:
                logging.warning("⚠️ Starting application without database connection - some features may be limited")
        except Exception as e:
            logging.error(f"⚠️ Database connection failed during startup: {e}")
            logging.warning("🚀 Continuing startup without database - health and simplified endpoints will still work")
            # Allow app to start without database for testing purposes
    
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
        prefix="/api/orders",
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
    
    # Simplified Notification routes (HTTP only - Heroku friendly)
    app.include_router(
        simple_notification_controller.router,
        prefix="/api",
        tags=["simple-notifications"],
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
