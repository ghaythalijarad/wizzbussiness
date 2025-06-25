"""
Authentication controller using OOP principles.
"""
from fastapi import APIRouter, Depends, HTTPException
from fastapi_users.exceptions import UserAlreadyExists
import logging
from datetime import datetime

from ..schemas.user import ChangePassword, UserCreate, UserRead, UserUpdate
from ..schemas.business import BusinessCreate, AddressCreate
from ..services.auth_service import UserManager, get_user_manager, auth_service
from ..services.business_service import business_service
from ..models.user import User
from ..models.business import BusinessType


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
            """Custom registration endpoint with proper error handling and automatic business creation."""
            try:
                # Create the user first
                user = await user_manager.create(user_data, safe=True)
                logging.info(f"User created successfully: {user.id}")
                
                # Automatically create a business for the user if they have business data
                if user.business_name and user.business_type:
                    try:
                        # Convert date_of_birth string to datetime
                        birth_date = datetime.now()
                        if user_data.date_of_birth:
                            try:
                                # Try different date formats
                                for fmt in ['%Y-%m-%d', '%Y-%m-%dT%H:%M:%S', '%d/%m/%Y', '%m/%d/%Y']:
                                    try:
                                        birth_date = datetime.strptime(user_data.date_of_birth, fmt)
                                        break
                                    except ValueError:
                                        continue
                            except:
                                birth_date = datetime(1990, 1, 1)  # Default fallback
                        
                        # Extract address from user data or use defaults
                        address_data = user_data.address or {}
                        address_create = AddressCreate(
                            country=address_data.get('country', 'Iraq'),
                            city=address_data.get('city', 'Baghdad'), 
                            district=address_data.get('district', 'Central'),
                            neighbourhood=address_data.get('neighbourhood', address_data.get('neighborhood', 'Downtown')),
                            street=address_data.get('street', 'Main Street'),
                            building_number=address_data.get('building_number', '1'),
                            zip_code=address_data.get('zip_code', '10001'),
                            latitude=None,
                            longitude=None
                        )
                        
                        # Convert business type string to enum
                        business_type_enum = BusinessType(user.business_type.lower())
                        
                        # Create business data from user registration data
                        business_data = BusinessCreate(
                            # Owner information
                            owner_name=user_data.owner_name or user.business_name or 'Business Owner',
                            owner_national_id=user_data.national_id or '0000000000',
                            owner_date_of_birth=birth_date,
                            
                            # Business information  
                            name=user.business_name,
                            business_type=business_type_enum,
                            phone_number=user.phone_number or '+9641234567890',
                            email=user.email,
                            
                            # Address information
                            address=address_create
                        )
                        
                        # Create the business
                        business = await business_service.create_business(business_data, user)
                        logging.info(f"Business created successfully for user {user.id}: {business.id}")
                        
                    except Exception as business_error:
                        logging.error(f"Failed to create business for user {user.id}: {business_error}")
                        # Don't fail the registration if business creation fails
                        # User can create business manually later
                
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
                logging.error(f"Registration failed: {e}")
                raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")


class UserController:
    """User management controller class."""
    
    def __init__(self):
        self.router = APIRouter()
        self._setup_routes()
    
    def _setup_routes(self):
        """Setup user management routes."""
        
        @self.router.get("/me", response_model=UserRead)
        async def get_me(user: User = Depends(auth_service.get_current_active_user())):
            """Get current user information with business details."""
            # Get business information to include owner name
            owner_name = None
            try:
                if user.id:
                    businesses = await business_service.get_businesses_by_owner(user.id)
                    if businesses:
                        # Get owner name from the first business (users typically have one main business)
                        owner_name = businesses[0].owner_name
            except Exception as e:
                logging.warning(f"Could not fetch business details for user {user.id}: {e}")
            
            return UserRead(
                id=str(user.id),
                email=user.email,
                is_active=user.is_active,
                is_superuser=user.is_superuser,
                is_verified=user.is_verified,
                phone_number=user.phone_number,
                business_name=user.business_name,
                business_type=user.business_type,
                owner_name=owner_name,
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
