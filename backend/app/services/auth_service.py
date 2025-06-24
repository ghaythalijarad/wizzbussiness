"""
Authentication service using OOP principles.
"""
from typing import AsyncGenerator
from fastapi import Depends
from fastapi_users import FastAPIUsers, BaseUserManager
from fastapi_users.authentication import AuthenticationBackend, BearerTransport, JWTStrategy
from fastapi_users.db import BeanieUserDatabase, ObjectIDIDMixin
from beanie import PydanticObjectId

from ..models.user import User
from ..core.config import config


class UserManager(ObjectIDIDMixin, BaseUserManager[User, PydanticObjectId]):
    """User manager class with OOP principles."""
    
    def __init__(self, user_db: BeanieUserDatabase):
        super().__init__(user_db)
        self.reset_password_token_secret = config.security.reset_password_token_secret
        self.verification_token_secret = config.security.verification_token_secret
    
    async def on_after_register(self, user: User, request = None):
        """Called after a user is registered."""
        print(f"User {user.id} has registered.")
    
    async def on_after_forgot_password(self, user: User, token: str, request = None):
        """Called after a user requests password reset."""
        print(f"User {user.id} has requested password reset. Token: {token}")
    
    async def on_after_reset_password(self, user: User, request = None):
        """Called after a user resets their password."""
        print(f"User {user.id} has reset their password.")


# Database dependency
async def get_user_db() -> AsyncGenerator[BeanieUserDatabase, None]:
    """Database dependency for user operations."""
    yield BeanieUserDatabase(User)


# User manager dependency
async def get_user_manager(user_db: BeanieUserDatabase = Depends(get_user_db)) -> AsyncGenerator[UserManager, None]:
    """User manager dependency."""
    yield UserManager(user_db)


class AuthenticationService:
    """Authentication service class managing all auth-related operations."""
    
    def __init__(self):
        self._fastapi_users = None
        self._auth_backend = None
        self._current_active_user = None
    
    def get_jwt_strategy(self) -> JWTStrategy:
        """JWT authentication strategy."""
        # Ensure secret_key is not None
        secret_key = config.security.secret_key
        if not secret_key:
            raise ValueError("SECRET_KEY must be set")
        
        return JWTStrategy(
            secret=secret_key, 
            lifetime_seconds=config.security.jwt_lifetime_seconds
        )
    
    def get_auth_backend(self) -> AuthenticationBackend:
        """Authentication backend configuration."""
        if self._auth_backend is None:
            bearer_transport = BearerTransport(tokenUrl="auth/jwt/login")
            self._auth_backend = AuthenticationBackend(
                name="jwt",
                transport=bearer_transport,
                get_strategy=self.get_jwt_strategy,
            )
        return self._auth_backend
    
    def get_fastapi_users(self) -> FastAPIUsers[User, PydanticObjectId]:
        """FastAPI Users instance."""
        if self._fastapi_users is None:
            self._fastapi_users = FastAPIUsers[User, PydanticObjectId](
                get_user_manager,
                [self.get_auth_backend()],
            )
        return self._fastapi_users
    
    def get_current_active_user(self):
        """Current active user dependency."""
        if self._current_active_user is None:
            self._current_active_user = self.get_fastapi_users().current_user(active=True)
        return self._current_active_user


# Create global instance (Singleton pattern)
auth_service = AuthenticationService()

# Export current active user dependency
current_active_user = auth_service.get_current_active_user()
