"""
POS Settings Controller for managing Point of Sale integrations
"""
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from beanie import PydanticObjectId

from ..models.user import User  
from ..models.pos_settings import (
    PosSettings, PosTestConnection, PosConnectionResult,
    PosOrderSyncLog, PosSystemType
)
from ..schemas.pos_schemas import (
    PosSettingsBase, PosSettingsCreate, PosSettingsUpdate, PosSettingsResponse,
    PosTestRequest, PosConnectionResponse, PosSyncLogResponse,
    PosSystemInfo
)
from ..services.pos_settings_service import PosSettingsService
from ..services.auth_service import current_active_user


class PosController:
    """POS Settings controller class."""
    
    def __init__(self):
        self.router = APIRouter(prefix="/pos", tags=["POS Settings"])
        self.service = PosSettingsService()
        self._setup_routes()
    
    async def _sync_order_background(self, business_id: PydanticObjectId, order_id: str):
        """Background task to sync order to POS"""
        try:
            # Note: This would need to fetch the Order object from order_id
            # For now, just log the attempt
            print(f"Syncing order {order_id} to POS for business {business_id}")
            # await self.service.send_order_to_pos(business_id, order_object)
        except Exception as e:
            print(f"Failed to sync order {order_id}: {e}")
    
    def _setup_routes(self):
        """Setup POS routes."""
        
        @self.router.get("/systems", response_model=List[PosSystemInfo])
        async def get_supported_systems():
            """Get list of supported POS systems."""
            return [
                PosSystemInfo(
                    type=PosSystemType.SQUARE,
                    name="Square",
                    description="Square Point of Sale system with payment processing",
                    api_docs_url="https://developer.squareup.com/docs",
                    required_fields=["api_endpoint", "api_key", "access_token", "location_id"],
                    optional_fields=[]
                ),
                PosSystemInfo(
                    type=PosSystemType.TOAST,
                    name="Toast POS",
                    description="Restaurant-focused POS system with kitchen management",
                    api_docs_url="https://doc.toasttab.com/",
                    required_fields=["api_endpoint", "access_token", "location_id"],
                    optional_fields=["api_key"]
                ),
                PosSystemInfo(
                    type=PosSystemType.CLOVER,
                    name="Clover",
                    description="Versatile POS system for retail and restaurants",
                    api_docs_url="https://docs.clover.com/",
                    required_fields=["api_endpoint", "access_token"],
                    optional_fields=["location_id"]
                ),
                PosSystemInfo(
                    type=PosSystemType.SHOPIFY_POS,
                    name="Shopify POS",
                    description="Integrated POS for Shopify stores",
                    api_docs_url="https://shopify.dev/docs/api/admin-rest",
                    required_fields=["api_endpoint", "access_token"],
                    optional_fields=["location_id"]
                ),
                PosSystemInfo(
                    type=PosSystemType.GENERIC_API,
                    name="Generic API",
                    description="Custom REST API integration",
                    api_docs_url="",
                    required_fields=["api_endpoint", "api_key"],
                    optional_fields=["access_token", "location_id"]
                )
            ]
        
        @self.router.get("/{business_id}/settings", response_model=PosSettingsResponse)
        async def get_pos_settings(
            business_id: str,
            current_user: User = Depends(current_active_user)
        ):
            """Get POS settings for a business."""
            try:
                business_id_obj = PydanticObjectId(business_id)
                settings = await self.service.get_business_pos_settings(business_id_obj)
                
                if not settings:
                    # Return default settings if none exist
                    settings = PosSettings()
                
                # Convert PosSettings to PosSettingsBase for response
                settings_dict = settings.to_dict()
                settings_base = PosSettingsBase(**settings_dict)
                
                return PosSettingsResponse(
                    business_id=business_id,
                    settings=settings_base,
                    last_updated=settings.last_connection_test,
                    connection_status=settings.last_connection_status,
                    last_test_date=settings.last_connection_test
                )
                
            except Exception as e:
                raise HTTPException(status_code=400, detail=f"Invalid business ID: {str(e)}")
        
        @self.router.post("/{business_id}/settings", response_model=PosSettingsResponse)
        async def create_pos_settings(
            business_id: str,
            settings_data: PosSettingsCreate,
            current_user: User = Depends(current_active_user)
        ):
            """Create POS settings for a business."""
            try:
                business_id_obj = PydanticObjectId(business_id)
                
                # Create POS settings object
                settings = PosSettings(**settings_data.dict())
                
                # Save settings
                success = await self.service.save_business_pos_settings(business_id_obj, settings)
                
                if not success:
                    raise HTTPException(status_code=500, detail="Failed to save POS settings")
                
                # Convert to response format
                settings_dict = settings.to_dict()
                settings_base = PosSettingsBase(**settings_dict)
                
                return PosSettingsResponse(
                    business_id=business_id,
                    settings=settings_base,
                    last_updated=datetime.utcnow()
                )
                
            except Exception as e:
                raise HTTPException(status_code=400, detail=f"Failed to create POS settings: {str(e)}")
        
        @self.router.put("/{business_id}/settings", response_model=PosSettingsResponse) 
        async def update_pos_settings(
            business_id: str,
            settings_data: PosSettingsUpdate,
            current_user: User = Depends(current_active_user)
        ):
            """Update POS settings for a business."""
            try:
                business_id_obj = PydanticObjectId(business_id)
                
                # Get existing settings
                existing_settings = await self.service.get_business_pos_settings(business_id_obj)
                if not existing_settings:
                    existing_settings = PosSettings()
                
                # Update with new data
                update_data = settings_data.dict(exclude_unset=True)
                for key, value in update_data.items():
                    setattr(existing_settings, key, value)
                
                # Save updated settings
                success = await self.service.save_business_pos_settings(business_id_obj, existing_settings)
                
                if not success:
                    raise HTTPException(status_code=500, detail="Failed to update POS settings")
                
                # Convert to response format
                settings_dict = existing_settings.to_dict()
                settings_base = PosSettingsBase(**settings_dict)
                
                return PosSettingsResponse(
                    business_id=business_id,
                    settings=settings_base,
                    last_updated=datetime.utcnow()
                )
                
            except Exception as e:
                raise HTTPException(status_code=400, detail=f"Failed to update POS settings: {str(e)}")
        
        @self.router.delete("/{business_id}/settings")
        async def delete_pos_settings(
            business_id: str,
            current_user: User = Depends(current_active_user)
        ):
            """Delete POS settings for a business."""
            try:
                business_id_obj = PydanticObjectId(business_id)
                
                success = await self.service.delete_business_pos_settings(business_id_obj)
                
                if not success:
                    raise HTTPException(status_code=404, detail="POS settings not found")
                
                return {"message": "POS settings deleted successfully"}
                
            except Exception as e:
                raise HTTPException(status_code=400, detail=f"Failed to delete POS settings: {str(e)}")
        
        @self.router.post("/{business_id}/test-connection", response_model=PosConnectionResponse)
        async def test_pos_connection(
            business_id: str,
            test_request: PosTestRequest,
            current_user: User = Depends(current_active_user)
        ):
            """Test connection to POS system."""
            try:
                business_id_obj = PydanticObjectId(business_id)
                
                # Create test configuration
                test_config = PosTestConnection(**test_request.dict())
                
                # Test connection
                result = await self.service.test_pos_connection(test_config)
                
                # Update settings with test result if business settings exist
                existing_settings = await self.service.get_business_pos_settings(business_id_obj)
                if existing_settings:
                    existing_settings.last_connection_test = datetime.utcnow()
                    existing_settings.last_connection_status = result.success
                    existing_settings.last_error_message = result.error_details
                    await self.service.save_business_pos_settings(business_id_obj, existing_settings)
                
                return PosConnectionResponse(
                    success=result.success,
                    message=result.message,
                    response_time_ms=result.response_time_ms,
                    error_details=result.error_details,
                    system_info=result.system_info,
                    tested_at=datetime.utcnow()
                )
                
            except Exception as e:
                raise HTTPException(status_code=400, detail=f"Connection test failed: {str(e)}")
        
        @self.router.get("/{business_id}/sync-logs", response_model=List[PosSyncLogResponse])
        async def get_sync_logs(
            business_id: str,
            limit: int = 50,
            skip: int = 0,
            current_user: User = Depends(current_active_user)
        ):
            """Get POS order sync logs for a business."""
            try:
                business_id_obj = PydanticObjectId(business_id)
                
                logs = await PosOrderSyncLog.find(
                    PosOrderSyncLog.business_id == business_id_obj
                ).sort("-sync_timestamp").skip(skip).limit(limit).to_list()
                
                return [
                    PosSyncLogResponse(
                        id=str(log.id),
                        business_id=business_id,
                        order_id=log.order_id,
                        pos_system_type=log.pos_system_type,
                        sync_status=log.sync_status,
                        sync_timestamp=log.sync_timestamp,
                        pos_order_id=log.pos_order_id,
                        error_message=log.error_message,
                        retry_count=log.retry_count
                    ) for log in logs
                ]
                
            except Exception as e:
                raise HTTPException(status_code=400, detail=f"Failed to get sync logs: {str(e)}")
        
        @self.router.post("/{business_id}/sync-order")
        async def sync_order_to_pos(
            business_id: str,
            order_id: str,
            background_tasks: BackgroundTasks,
            current_user: User = Depends(current_active_user)
        ):
            """Manually sync an order to POS system."""
            try:
                business_id_obj = PydanticObjectId(business_id)
                
                # Add background task to sync order
                background_tasks.add_task(
                    self._sync_order_background,
                    business_id_obj,
                    order_id
                )
                
                return {"message": "Order sync initiated", "order_id": order_id}
                
            except Exception as e:
                raise HTTPException(status_code=400, detail=f"Failed to initiate order sync: {str(e)}")


# Create controller instance
pos_controller = PosController()
