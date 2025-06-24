"""
Business service using OOP principles.
"""
from typing import List, Optional, Dict, Any
from beanie import PydanticObjectId
from fastapi import HTTPException

from ..models.business import Business, Restaurant, Store, Pharmacy, Kitchen, BusinessType, BusinessStatus, Address, BusinessSettings
from ..models.user import User
from ..schemas.business import BusinessCreate, BusinessUpdate, POSSettingsUpdate, BusinessStatusUpdate


class BusinessService:
    """Business service class handling all business-related operations."""
    
    def __init__(self):
        self._business_models = {
            BusinessType.RESTAURANT: Restaurant,
            BusinessType.STORE: Store,
            BusinessType.PHARMACY: Pharmacy,
            BusinessType.KITCHEN: Kitchen,
        }
    
    def _get_business_model(self, business_type: BusinessType):
        """Get the appropriate business model class."""
        return self._business_models.get(business_type, Business)
    
    async def create_business(self, business_data: BusinessCreate, owner: User) -> Business:
        """Create a new business with dual-storage approach."""
        try:
            # Get the appropriate business model
            BusinessModel = self._get_business_model(business_data.business_type)
            
            # Create address
            address = Address(**business_data.address.dict())
            
            # Create business settings with defaults
            settings = BusinessSettings()
            if business_data.settings:
                if business_data.settings.pos:
                    settings.pos.update(business_data.settings.pos)
                if business_data.settings.notifications:
                    settings.notifications.update(business_data.settings.notifications)
                if business_data.settings.operating_hours:
                    settings.operating_hours.update(business_data.settings.operating_hours)
            
            # Create business data
            business_dict = business_data.dict(exclude={"address", "settings"})
            business_dict.update({
                "owner_id": owner.id,
                "address": address,
                "settings": settings,
                "documents": business_data.documents or {}
            })
            
            # Create business instance in specific collection
            business = BusinessModel(**business_dict)
            await business.save()
            
            # DUAL STORAGE: Also save to unified WB_businesses collection for dashboard
            unified_business_dict = business_dict.copy()
            # Use base Business model for unified collection
            unified_business = Business(**unified_business_dict)
            # Override the ID to maintain consistency
            unified_business.id = business.id
            await unified_business.save()
            
            return business
            
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Failed to create business: {str(e)}")
    
    async def get_business_by_id(self, business_id: str) -> Optional[Business]:
        """Get business by ID."""
        try:
            business_obj_id = PydanticObjectId(business_id)
            
            # Try to find in each business model
            for BusinessModel in [Business, Restaurant, Store, Pharmacy, Kitchen]:
                business = await BusinessModel.get(business_obj_id)
                if business:
                    return business
            
            return None
        except Exception:
            return None
    
    async def get_businesses_by_owner(self, owner_id: PydanticObjectId) -> List[Business]:
        """Get all businesses owned by a specific user."""
        businesses = []
        
        # Search in each business model
        for BusinessModel in [Restaurant, Store, Pharmacy, Kitchen]:
            model_businesses = await BusinessModel.find(BusinessModel.owner_id == owner_id).to_list()
            businesses.extend(model_businesses)
        
        return businesses
    
    async def get_all_businesses_unified(self) -> List[Business]:
        """Get all businesses from the unified WB_businesses collection for dashboard."""
        return await Business.find().to_list()
    
    async def get_businesses_by_type_unified(self, business_type: BusinessType) -> List[Business]:
        """Get businesses by type from unified collection."""
        return await Business.find(Business.business_type == business_type).to_list()
    
    async def get_businesses_by_status_unified(self, status: BusinessStatus) -> List[Business]:
        """Get businesses by status from unified collection."""
        return await Business.find(Business.status == status).to_list()
    
    async def search_businesses_unified(self, search_term: str) -> List[Business]:
        """Search businesses by name or other fields from unified collection."""
        regex_pattern = {"$regex": search_term, "$options": "i"}
        return await Business.find({
            "$or": [
                {"name": regex_pattern},
                {"owner_name": regex_pattern},
                {"email": regex_pattern}
            ]
        }).to_list()
    
    async def get_businesses_by_type(self, business_type: BusinessType) -> List[Business]:
        """Get all businesses of a specific type."""
        return await Business.find(Business.business_type == business_type).to_list()
    
    async def update_business(self, business_id: str, business_data: BusinessUpdate, owner: User) -> Business:
        """Update business information with dual-collection sync."""
        business = await self.get_business_by_id(business_id)
        if not business:
            raise HTTPException(status_code=404, detail="Business not found")
        
        if business.owner_id != owner.id:
            raise HTTPException(status_code=403, detail="Not authorized to update this business")
        
        try:
            # Update fields
            update_data = business_data.dict(exclude_unset=True)
            
            if "address" in update_data:
                address_data = update_data.pop("address")
                business.address = Address(**address_data)
            
            if "settings" in update_data:
                settings_data = update_data.pop("settings")
                if not business.settings:
                    business.settings = BusinessSettings()
                
                for key, value in settings_data.items():
                    if hasattr(business.settings, key) and value is not None:
                        setattr(business.settings, key, value)
            
            # Update other fields
            for key, value in update_data.items():
                if hasattr(business, key) and value is not None:
                    setattr(business, key, value)
            
            await business.save()
            
            # DUAL STORAGE: Also update in unified WB_businesses collection
            unified_business = await Business.get(business.id)
            if unified_business:
                # Sync the changes to unified collection
                for key, value in update_data.items():
                    if hasattr(unified_business, key) and value is not None:
                        setattr(unified_business, key, value)
                if business.address:
                    unified_business.address = business.address
                if business.settings:
                    unified_business.settings = business.settings
                await unified_business.save()
            
            return business
            
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Failed to update business: {str(e)}")
    
    async def update_pos_settings(self, business_id: str, pos_settings: POSSettingsUpdate, owner: User) -> Business:
        """Update POS settings for a business."""
        business = await self.get_business_by_id(business_id)
        if not business:
            raise HTTPException(status_code=404, detail="Business not found")
        
        if business.owner_id != owner.id:
            raise HTTPException(status_code=403, detail="Not authorized to update this business")
        
        try:
            # Update POS settings
            pos_data = pos_settings.dict(exclude_unset=True)
            business.update_pos_settings(pos_data)
            
            await business.save()
            return business
            
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Failed to update POS settings: {str(e)}")
    
    async def get_pos_settings(self, business_id: str, owner: User) -> Dict[str, Any]:
        """Get POS settings for a business."""
        business = await self.get_business_by_id(business_id)
        if not business:
            raise HTTPException(status_code=404, detail="Business not found")
        
        if business.owner_id != owner.id:
            raise HTTPException(status_code=403, detail="Not authorized to view this business")
        
        return business.get_pos_settings()
    
    async def set_business_online_status(self, business_id: str, is_online: bool, owner: User) -> Business:
        """Set business online/offline status."""
        business = await self.get_business_by_id(business_id)
        if not business:
            raise HTTPException(status_code=404, detail="Business not found")
        
        if business.owner_id != owner.id:
            raise HTTPException(status_code=403, detail="Not authorized to update this business")
        
        business.set_online_status(is_online)
        await business.save()
        return business
    
    async def update_business_status(self, business_id: str, status_data: BusinessStatusUpdate) -> Business:
        """Update business status (admin only)."""
        business = await self.get_business_by_id(business_id)
        if not business:
            raise HTTPException(status_code=404, detail="Business not found")
        
        try:
            business.status = status_data.status
            if status_data.is_verified is not None:
                business.is_verified = status_data.is_verified
            
            await business.save()
            return business
            
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Failed to update business status: {str(e)}")
    
    async def delete_business(self, business_id: str, owner: User) -> bool:
        """Delete a business from both collections."""
        business = await self.get_business_by_id(business_id)
        if not business:
            raise HTTPException(status_code=404, detail="Business not found")
        
        if business.owner_id != owner.id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this business")
        
        try:
            # Delete from specific collection
            await business.delete()
            
            # DUAL STORAGE: Also delete from unified WB_businesses collection
            unified_business = await Business.get(business.id)
            if unified_business:
                await unified_business.delete()
            
            return True
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Failed to delete business: {str(e)}")
    
    async def search_businesses(self, 
                               query: Optional[str] = None,
                               business_type: Optional[BusinessType] = None,
                               status: Optional[BusinessStatus] = None,
                               is_online: Optional[bool] = None,
                               limit: int = 20,
                               skip: int = 0) -> List[Business]:
        """Search businesses with filters."""
        filters = {}
        
        if business_type:
            filters["business_type"] = business_type
        if status:
            filters["status"] = status
        if is_online is not None:
            filters["is_online"] = is_online
        
        if query:
            # Simple text search on name (in production, you might want to use full-text search)
            import re
            regex_pattern = re.compile(query, re.IGNORECASE)
            filters["name"] = {"$regex": regex_pattern}
        
        return await Business.find(filters).skip(skip).limit(limit).to_list()


# Create global instance
business_service = BusinessService()
