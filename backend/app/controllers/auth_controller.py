"""
Authentication controller using OOP principles.
"""
from fastapi import APIRouter, Depends, HTTPException
from fastapi_users.exceptions import UserAlreadyExists

from ..schemas.user import ChangePassword, UserCreate, UserRead, UserUpdate
from ..services.auth_service import UserManager, get_user_manager, auth_service
from ..models.user import User


class AuthController:
    """Authentication controller class."""
    
    def __init__(self):
        self.router = APIRouter()
        self._setup_routes()
    
    def _setup_routes(self):
        """Setup authentication routes."""
        
        @self.router.post("/register", response_model=UserRead, status_code=201)
        async def register_user(
            user_data: UserCreate, 
            user_manager: UserManager = Depends(get_user_manager)
        ):
            """Custom registration endpoint with proper error handling."""
            try:
                user = await user_manager.create(user_data, safe=True)
                return UserRead(
                    id=str(user.id),
                    email=user.email,
                    is_active=user.is_active,
                    is_superuser=user.is_superuser,
                    is_verified=user.is_verified,
                    phone_number=user.phone_number,
                    business_name=user.business_name,
                    business_type=user.business_type,
                )
            except UserAlreadyExists:
                raise HTTPException(status_code=400, detail="REGISTER_USER_ALREADY_EXISTS")
            except ValueError as e:
                raise HTTPException(status_code=400, detail=str(e))
            except Exception as e:
                raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")

        @self.router.post("/change-password")
        async def change_password(
            change: ChangePassword,
            user: User = Depends(auth_service.get_current_active_user()),
            user_manager: UserManager = Depends(get_user_manager),
        ):
            """Change password for current user"""
            # Verify old password
            valid = await user_manager.verify_password(change.old_password, user.hashed_password)
            if not valid:
                raise HTTPException(status_code=400, detail="Incorrect old password")
            # Update to new password
            update_data = UserUpdate(password=change.new_password)
            updated_user = await user_manager.update(user, update_data)
            return {"success": True, "message": "Password changed successfully"}


class UserController:
    """User management controller class."""
    
    def __init__(self):
        self.router = APIRouter()
        self._setup_routes()
    
    def _setup_routes(self):
        """Setup user management routes."""
        
        @self.router.get("/me", response_model=UserRead)
        async def get_me(user: User = Depends(auth_service.get_current_active_user())):
            """Get current user information."""
            return UserRead(
                id=str(user.id),
                email=user.email,
                is_active=user.is_active,
                is_superuser=user.is_superuser,
                is_verified=user.is_verified,
                phone_number=user.phone_number,
                business_name=user.business_name,
                business_type=user.business_type,
            )
        
        @self.router.get("/protected")
        async def protected_route(user: User = Depends(auth_service.get_current_active_user())):
            """Protected route example."""
            return {
                "message": "This is a protected route",
                "user": user.to_dict()
            }


# Create controller instances
auth_controller = AuthController()
user_controller = UserController()
