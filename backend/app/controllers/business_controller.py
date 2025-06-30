"""
Business controller using OOP principles.
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from beanie import PydanticObjectId
from sqlalchemy.ext.asyncio import AsyncSession

from ..models.user_sql import User
from ..models.business_sql import BusinessType, BusinessStatus
from ..core.db_manager import get_async_session
from ..schemas.business import (
    BusinessCreate, BusinessRead, BusinessUpdate, 
    POSSettingsUpdate, BusinessStatusUpdate,
    RestaurantCreate, StoreCreate, PharmacyCreate, KitchenCreate
)
from ..services.business_service import business_service
from ..services.auth_service import current_active_user


class BusinessController:
    """Business controller class."""
    
    def __init__(self):
        self.router = APIRouter()
        self._setup_routes()
    
    def _setup_routes(self):
        """Setup business routes."""
        
        @self.router.post("/", response_model=BusinessRead)
        async def create_business(
            business_data: BusinessCreate,
            current_user: User = Depends(current_active_user),
            session: AsyncSession = Depends(get_async_session)
        ):
            """Create a new business."""
            business = await business_service.create_business(business_data, current_user, session)
            # Optionally fetch with address if needed
            return BusinessRead.from_orm(business)
        
        @self.router.post("/restaurant", response_model=BusinessRead)
        async def create_restaurant(
            restaurant_data: RestaurantCreate,
            current_user: User = Depends(current_active_user)
        ):
            """Create a new restaurant."""
            business = await business_service.create_business(restaurant_data, current_user)
            return BusinessRead(**business.to_dict())
        
        @self.router.post("/store", response_model=BusinessRead)
        async def create_store(
            store_data: StoreCreate,
            current_user: User = Depends(current_active_user)
        ):
            """Create a new store."""
            business = await business_service.create_business(store_data, current_user)
            return BusinessRead(**business.to_dict())
        
        @self.router.post("/pharmacy", response_model=BusinessRead)
        async def create_pharmacy(
            pharmacy_data: PharmacyCreate,
            current_user: User = Depends(current_active_user)
        ):
            """Create a new pharmacy."""
            business = await business_service.create_business(pharmacy_data, current_user)
            return BusinessRead(**business.to_dict())
        
        @self.router.post("/kitchen", response_model=BusinessRead)
        async def create_kitchen(
            kitchen_data: KitchenCreate,
            current_user: User = Depends(current_active_user)
        ):
            """Create a new kitchen."""
            business = await business_service.create_business(kitchen_data, current_user)
            return BusinessRead(**business.to_dict())
        
        @self.router.get("/my-businesses", response_model=List[BusinessRead])
        async def get_my_businesses(
            current_user: User = Depends(current_active_user),
            session: AsyncSession = Depends(get_async_session)
        ):
            """Get all businesses owned by the current user."""
            businesses = await business_service.get_businesses_by_owner(current_user.id, session)
            return [BusinessRead.from_orm(business) for business in businesses]

        @self.router.get("/{business_id}", response_model=BusinessRead)
        async def get_business(
            business_id: int,
            current_user: User = Depends(current_active_user),
            session: AsyncSession = Depends(get_async_session)
        ):
            """Get a specific business."""
            business = await business_service.get_business_by_id(business_id, session)
            if not business:
                raise HTTPException(status_code=404, detail="Business not found")
            if business.owner_id != current_user.id:
                raise HTTPException(status_code=403, detail="Not authorized to view this business")
            return BusinessRead.from_orm(business)
        
        @self.router.put("/{business_id}", response_model=BusinessRead)
        async def update_business(
            business_id: str,
            business_data: BusinessUpdate,
            current_user: User = Depends(current_active_user)
        ):
            """Update business information."""
            business = await business_service.update_business(business_id, business_data, current_user)
            return BusinessRead(**business.to_dict())
        
        @self.router.put("/{business_id}/pos-settings")
        async def update_pos_settings(
            business_id: str,
            pos_settings: POSSettingsUpdate,
            current_user: User = Depends(current_active_user)
        ):
            """Update POS settings for a business."""
            business = await business_service.update_pos_settings(business_id, pos_settings, current_user)
            return {
                "message": "POS settings updated successfully",
                "pos_settings": business.get_pos_settings()
            }
        
        @self.router.get("/{business_id}/pos-settings")
        async def get_pos_settings(
            business_id: str,
            current_user: User = Depends(current_active_user)
        ):
            """Get POS settings for a business."""
            pos_settings = await business_service.get_pos_settings(business_id, current_user)
            return {"pos_settings": pos_settings}
        
        @self.router.put("/{business_id}/online-status")
        async def set_online_status(
            business_id: str,
            is_online: bool,
            current_user: User = Depends(current_active_user)
        ):
            """Set business online/offline status."""
            business = await business_service.set_business_online_status(business_id, is_online, current_user)
            return {
                "message": f"Business {'online' if is_online else 'offline'} status updated",
                "is_online": business.is_online
            }
        
        @self.router.delete("/{business_id}")
        async def delete_business(
            business_id: str,
            current_user: User = Depends(current_active_user)
        ):
            """Delete a business."""
            await business_service.delete_business(business_id, current_user)
            return {"message": "Business deleted successfully"}
        
        @self.router.get("/search/", response_model=List[BusinessRead])
        async def search_businesses(
            query: Optional[str] = Query(None, description="Search query"),
            business_type: Optional[BusinessType] = Query(None, description="Business type filter"),
            status: Optional[BusinessStatus] = Query(None, description="Business status filter"),
            is_online: Optional[bool] = Query(None, description="Online status filter"),
            limit: int = Query(20, ge=1, le=100, description="Number of results to return"),
            skip: int = Query(0, ge=0, description="Number of results to skip")
        ):
            """Search businesses with filters."""
            businesses = await business_service.search_businesses(
                query=query,
                business_type=business_type,
                status=status,
                is_online=is_online,
                limit=limit,
                skip=skip
            )
            return [BusinessRead(**business.to_dict()) for business in businesses]
        
        @self.router.get("/dashboard/all", response_model=List[BusinessRead])
        async def get_all_businesses_dashboard(
            business_type: Optional[BusinessType] = Query(None),
            status: Optional[BusinessStatus] = Query(None),
            search: Optional[str] = Query(None),
            limit: int = Query(50, ge=1, le=200),
            skip: int = Query(0, ge=0),
            current_user: User = Depends(current_active_user)
        ):
            """Get all businesses from unified collection for dashboard."""
            if not current_user.is_superuser:
                raise HTTPException(status_code=403, detail="Admin access required")
            
            if search:
                businesses = await business_service.search_businesses_unified(search)
            elif business_type:
                businesses = await business_service.get_businesses_by_type_unified(business_type)
            elif status:
                businesses = await business_service.get_businesses_by_status_unified(status)
            else:
                businesses = await business_service.get_all_businesses_unified()
            
            # Apply pagination
            total_businesses = businesses[skip:skip + limit]
            return [BusinessRead(**business.to_dict()) for business in total_businesses]
        
        @self.router.get("/dashboard/stats")
        async def get_business_statistics(
            current_user: User = Depends(current_active_user)
        ):
            """Get business statistics for dashboard."""
            if not current_user.is_superuser:
                raise HTTPException(status_code=403, detail="Admin access required")
            
            all_businesses = await business_service.get_all_businesses_unified()
            
            stats = {
                "total": len(all_businesses),
                "by_type": {
                    "restaurant": len([b for b in all_businesses if b.business_type == BusinessType.RESTAURANT]),
                    "store": len([b for b in all_businesses if b.business_type == BusinessType.STORE]),
                    "pharmacy": len([b for b in all_businesses if b.business_type == BusinessType.PHARMACY]),
                    "kitchen": len([b for b in all_businesses if b.business_type == BusinessType.KITCHEN])
                },
                "by_status": {
                    "pending": len([b for b in all_businesses if b.status == BusinessStatus.PENDING]),
                    "approved": len([b for b in all_businesses if b.status == BusinessStatus.APPROVED]),
                    "rejected": len([b for b in all_businesses if b.status == BusinessStatus.REJECTED]),
                    "suspended": len([b for b in all_businesses if b.status == BusinessStatus.SUSPENDED])
                },
                "online": len([b for b in all_businesses if b.is_online]),
                "verified": len([b for b in all_businesses if b.is_verified])
            }
            
            return stats


class AdminBusinessController:
    """Admin business controller class for admin-only operations."""
    
    def __init__(self):
        self.router = APIRouter()
        self._setup_routes()
    
    def _setup_routes(self):
        """Setup admin business routes."""
        
        @self.router.put("/{business_id}/status")
        async def update_business_status(
            business_id: str,
            status_data: BusinessStatusUpdate,
            current_user: User = Depends(current_active_user)
        ):
            """Update business status (admin only)."""
            if not current_user.is_superuser:
                raise HTTPException(status_code=403, detail="Admin access required")
            
            business = await business_service.update_business_status(business_id, status_data)
            return {
                "message": "Business status updated successfully",
                "business": BusinessRead(**business.to_dict())
            }
        
        @self.router.get("/", response_model=List[BusinessRead])
        async def get_all_businesses(
            business_type: Optional[BusinessType] = Query(None),
            status: Optional[BusinessStatus] = Query(None),
            limit: int = Query(50, ge=1, le=200),
            skip: int = Query(0, ge=0),
            current_user: User = Depends(current_active_user)
        ):
            """Get all businesses (admin only)."""
            if not current_user.is_superuser:
                raise HTTPException(status_code=403, detail="Admin access required")
            
            businesses = await business_service.search_businesses(
                business_type=business_type,
                status=status,
                limit=limit,
                skip=skip
            )
            return [BusinessRead(**business.to_dict()) for business in businesses]


# Create controller instances
business_controller = BusinessController()
admin_business_controller = AdminBusinessController()
