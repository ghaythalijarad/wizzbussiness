"""
Fixed Application factory using OOP principles.
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
from .controllers.health_controller import health_controller
from .controllers.auth_controller import auth_controller
from .controllers.business_controller import business_controller, admin_business_controller
from .controllers.item_controller import item_controller, category_controller
from .controllers.order_controller import order_controller
from .controllers.notification_controller import notification_ws_controller
from .services.auth_service import auth_service


class ApplicationFactory:
    """Application factory class for creating FastAPI app with proper OOP structure."""
    
    def __init__(self):
        self.app = None
    
    def create_app(self) -> FastAPI:
        """Create and configure FastAPI application."""
        # Create FastAPI app first
        self.app = FastAPI(
            title=config.title,
            version=config.version,
            debug=config.debug
        )
        
        # Configure components in order
        self._configure_middleware()
        self._configure_events()
        self._configure_routes()
        self._configure_logging()
        self._configure_static_files()
        
        return self.app
    
    def _configure_static_files(self):
        """Configure static file serving."""
        uploads_dir = "uploads"
        if not os.path.exists(uploads_dir):
            os.makedirs(uploads_dir)
        self.app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")
    
    def _configure_middleware(self):
        """Configure application middleware."""
        # Security headers middleware
        @self.app.middleware("http")
        async def add_security_headers(request: Request, call_next):
            response = await call_next(request)
            response.headers["X-Content-Type-Options"] = "nosniff"
            response.headers["X-Frame-Options"] = "DENY"
            response.headers["X-XSS-Protection"] = "1; mode=block"
            response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
            return response
        
        # CORS middleware
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=config.cors.origins,
            allow_credentials=config.cors.allow_credentials,
            allow_methods=config.cors.allow_methods,
            allow_headers=config.cors.allow_headers,
        )
    
    def _configure_events(self):
        """Configure application startup and shutdown events."""
        
        @self.app.on_event("startup")
        async def startup_event():
            """Initialize database and other services on startup."""
            try:
                # Initialize database connection
                await db_manager.connect()
                
                # Drop any conflicting index to allow re-creation with case-insensitive collation
                db = db_manager.database
                users_coll = db.get_collection("WB_users")
                try:
                    await users_coll.drop_index("unique_email_idx")
                except Exception:
                    pass
                
                # Initialize Beanie ODM
                await init_beanie(database=db, document_models=[User, Business, Restaurant, Store, Pharmacy, Kitchen, Item, ItemCategory, Order])
                
                logging.info("Application startup completed successfully")
            except Exception as e:
                logging.error(f"Startup failed: {e}")
                raise
        
        @self.app.on_event("shutdown")
        async def shutdown_event():
            """Cleanup on application shutdown."""
            try:
                await db_manager.disconnect()
                logging.info("Application shutdown completed successfully")
            except Exception as e:
                logging.error(f"Shutdown failed: {e}")
                raise

    def _configure_routes(self):
        """Configure application routes."""
        # Health check routes
        self.app.include_router(
            health_controller.router,
            tags=["health"]
        )
        
        # Authentication routes
        fastapi_users = auth_service.get_fastapi_users()
        auth_backend = auth_service.get_auth_backend()
        
        # FastAPI-Users auth routes
        self.app.include_router(
            fastapi_users.get_auth_router(auth_backend),
            prefix="/auth/jwt",
            tags=["auth"],
        )
        
        # Custom auth routes
        self.app.include_router(
            auth_controller.router,
            prefix="/auth",
            tags=["auth"],
        )
        
        # Password reset routes
        self.app.include_router(
            fastapi_users.get_reset_password_router(),
            prefix="/auth",
            tags=["auth"],
        )
        
        # Verification routes
        from .schemas.user import UserRead, UserUpdate
        self.app.include_router(
            fastapi_users.get_verify_router(UserRead),
            prefix="/auth",
            tags=["auth"],
        )
        
        # User management routes
        self.app.include_router(
            fastapi_users.get_users_router(UserRead, UserUpdate),
            prefix="/users",
            tags=["users"],
        )
        
        # Business routes
        self.app.include_router(
            business_controller.router,
            prefix="/businesses",
            tags=["businesses"],
        )
        
        # Admin business routes
        self.app.include_router(
            admin_business_controller.router,
            prefix="/admin/businesses",
            tags=["admin", "businesses"],
        )
        
        # Item management routes
        self.app.include_router(
            item_controller,
            tags=["items"],
        )
        
        # Category management routes
        self.app.include_router(
            category_controller,
            tags=["categories"],
        )
        
        # Order management routes
        self.app.include_router(
            order_controller.router,
            prefix="/api/orders",
            tags=["orders"],
        )
        
        # Notification routes (WebSocket and HTTP)
        self.app.include_router(
            notification_ws_controller.router,
            prefix="/notifications",
            tags=["notifications"],
        )

    def _configure_logging(self):
        """Configure application logging."""
        logging.basicConfig(
            level=logging.INFO if not config.debug else logging.DEBUG,
            format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )


# Create application factory instance
app_factory = ApplicationFactory()


# Create the FastAPI app
def create_app() -> FastAPI:
    """Create FastAPI application."""
    return app_factory.create_app()
