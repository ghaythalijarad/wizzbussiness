"""
Business service using OOP principles, now with SQLAlchemy and PostgreSQL.
"""
from typing import List, Optional, Dict, Any
from fastapi import HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
import logging

from ..models.business_sql import Business, BusinessType, BusinessStatus, BusinessSettings
from ..models.address_sql import Address
from ..models.user_sql import User
from ..schemas.business import BusinessCreate, BusinessUpdate, POSSettingsUpdate, BusinessStatusUpdate
from .category_defaults_service import category_defaults_service
from ..core.db_manager import get_async_session


class BusinessService:
    """Business service class handling all business-related operations using SQLAlchemy."""

    async def create_business(self, business_data: BusinessCreate, owner: User, session: AsyncSession) -> Business:
        """Create a new business and related address using SQLAlchemy."""
        try:
            # Step 1: Create address
            address_data = business_data.address.dict()
            address = Address(**address_data)
            session.add(address)
            await session.flush()  # Get address.id

            # Step 2: Create business settings (if any)
            settings = None
            if business_data.settings:
                settings = BusinessSettings(**business_data.settings.dict())
                session.add(settings)
                await session.flush()

            # Step 3: Create business
            business = Business(
                owner_id=owner.id,
                name=business_data.name,
                business_type=business_data.business_type,
                phone_number=business_data.phone_number,
                email=business_data.email,
                address_id=address.id,
                settings_id=settings.id if settings else None,
                documents=business_data.documents or {},
                status=BusinessStatus.ACTIVE
            )
            session.add(business)
            await session.commit()
            await session.refresh(business)

            # Step 4: Optionally create default categories
            try:
                await category_defaults_service.create_default_categories(
                    business.id, business_data.business_type, session
                )
                logging.info(f"Created default categories for business {business.id}")
            except Exception as category_error:
                logging.error(f"Failed to create default categories for business {business.id}: {category_error}")

            return business
        except Exception as e:
            await session.rollback()
            raise HTTPException(status_code=400, detail=f"Failed to create business: {str(e)}")

    async def get_business_by_id(self, business_id: int, session: AsyncSession) -> Optional[Business]:
        """Get business by ID with address data included."""
        result = await session.execute(select(Business).where(Business.id == business_id))
        return result.scalar_one_or_none()

    async def get_business_with_address(self, business_id: str) -> Optional[Dict[str, Any]]:
        """Get business by ID with full address data for API responses."""
        business = await self.get_business_by_id(business_id)
        if not business:
            return None

        # Get business dict
        business_dict = business.to_dict()

        # Get full address data
        address_data = await business.get_address_dict()
        if address_data:
            business_dict["address"] = address_data

        return business_dict

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

    async def search_businesses(
            self,
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


# Singleton instance
business_service = BusinessService()
