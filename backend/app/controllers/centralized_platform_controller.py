"""
Controller for centralized platform operations.
Handles API endpoints for platform integration and management.
"""
import logging
from fastapi import APIRouter, HTTPException, Depends, Body
from typing import Dict, Any, List, Optional

from ..services.centralized_platform_service import CentralizedPlatformService
from ..services.business_service import business_service
from ..services.auth_service import current_active_user
from ..models.user import User
from ..models.business import Business

# Create router
centralized_platform_controller = APIRouter(
    prefix="/api/platform",
    tags=["Centralized Platform"]
)

# Initialize service
platform_service = CentralizedPlatformService()


@centralized_platform_controller.get("/test-connection")
async def test_platform_connection(
    current_user: User = Depends(current_active_user)
) -> Dict[str, Any]:
    """Test connection to the centralized platform."""
    try:
        result = await platform_service.test_connection()
        return {
            "message": "Platform connection test completed",
            "result": result
        }
    except Exception as e:
        logging.error(f"Error testing platform connection: {e}")
        raise HTTPException(status_code=500, detail="Failed to test platform connection")


@centralized_platform_controller.get("/apps")
async def get_platform_apps(
    current_user: User = Depends(current_active_user)
) -> Dict[str, Any]:
    """Get list of apps from the centralized platform."""
    try:
        apps = await platform_service.get_platform_apps()
        return {
            "message": f"Retrieved {len(apps)} apps from platform",
            "apps": apps,
            "count": len(apps)
        }
    except Exception as e:
        logging.error(f"Error getting platform apps: {e}")
        raise HTTPException(status_code=500, detail="Failed to get platform apps")


@centralized_platform_controller.post("/deploy")
async def deploy_centralized_app(
    app_config: Dict[str, Any] = Body(...),
    current_user: User = Depends(current_active_user)
) -> Dict[str, Any]:
    """Deploy or update the centralized platform app."""
    try:
        result = await platform_service.deploy_centralized_app(app_config)
        return {
            "message": "App deployment completed",
            "result": result
        }
    except Exception as e:
        logging.error(f"Error deploying centralized app: {e}")
        raise HTTPException(status_code=500, detail="Failed to deploy centralized app")


@centralized_platform_controller.post("/sync-business/{business_id}")
async def sync_business_to_platform(
    business_id: str,
    current_user: User = Depends(current_active_user)
) -> Dict[str, Any]:
    """Sync a specific business to the centralized platform."""
    try:
        # Get business data
        business = await business_service.get_business_by_id(business_id)
        if not business:
            raise HTTPException(status_code=404, detail="Business not found")
        
        # Sync to platform
        result = await platform_service.sync_business_data(business)
        
        return {
            "message": f"Business sync completed for {business.name}",
            "business_id": business_id,
            "result": result
        }
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error syncing business to platform: {e}")
        raise HTTPException(status_code=500, detail="Failed to sync business to platform")


@centralized_platform_controller.post("/sync-all-businesses")
async def sync_all_businesses_to_platform(
    current_user: User = Depends(current_active_user)
) -> Dict[str, Any]:
    """Sync all businesses to the centralized platform."""
    try:
        # Get all businesses
        businesses = await business_service.get_all_businesses_unified()
        
        sync_results = []
        for business in businesses:
            try:
                result = await platform_service.sync_business_data(business)
                sync_results.append({
                    "business_id": str(business.id),
                    "business_name": business.name,
                    "status": result.get("status", "unknown"),
                    "result": result
                })
            except Exception as e:
                logging.error(f"Error syncing business {business.name}: {e}")
                sync_results.append({
                    "business_id": str(business.id),
                    "business_name": business.name,
                    "status": "error",
                    "error": str(e)
                })
        
        successful_syncs = len([r for r in sync_results if r["status"] == "synced"])
        
        return {
            "message": f"Bulk sync completed. {successful_syncs}/{len(businesses)} businesses synced successfully",
            "total_businesses": len(businesses),
            "successful_syncs": successful_syncs,
            "results": sync_results
        }
    except Exception as e:
        logging.error(f"Error syncing all businesses to platform: {e}")
        raise HTTPException(status_code=500, detail="Failed to sync businesses to platform")


@centralized_platform_controller.get("/sync-status")
async def get_platform_sync_status(
    current_user: User = Depends(current_active_user)
) -> Dict[str, Any]:
    """Get the current sync status with the centralized platform."""
    try:
        # Test connection
        connection_test = await platform_service.test_connection()
        
        # Get app information
        apps = await platform_service.get_platform_apps()
        
        # Get business count
        businesses = await business_service.get_all_businesses_unified()
        
        return {
            "message": "Platform sync status retrieved",
            "platform_connection": connection_test,
            "platform_apps_count": len(apps),
            "local_businesses_count": len(businesses),
            "sync_recommended": connection_test.get("status") == "connected" and len(businesses) > 0
        }
    except Exception as e:
        logging.error(f"Error getting platform sync status: {e}")
        raise HTTPException(status_code=500, detail="Failed to get platform sync status")


@centralized_platform_controller.post("/setup-platform")
async def setup_centralized_platform(
    setup_config: Dict[str, Any] = Body(...),
    current_user: User = Depends(current_active_user)
) -> Dict[str, Any]:
    """Set up the complete centralized platform integration."""
    try:
        setup_results = []
        
        # Step 1: Test connection
        connection_test = await platform_service.test_connection()
        setup_results.append({
            "step": "connection_test",
            "status": connection_test.get("status"),
            "result": connection_test
        })
        
        if connection_test.get("status") != "connected":
            return {
                "message": "Platform setup failed - connection test failed",
                "results": setup_results,
                "success": False
            }
        
        # Step 2: Deploy centralized app
        app_config = setup_config.get("app_config", {
            "name": "delivery-platform-central",
            "region": "us"
        })
        
        deploy_result = await platform_service.deploy_centralized_app(app_config)
        setup_results.append({
            "step": "app_deployment",
            "status": deploy_result.get("status"),
            "result": deploy_result
        })
        
        # Step 3: Sync all businesses
        businesses = await business_service.get_all_businesses_unified()
        sync_count = 0
        
        for business in businesses:
            try:
                sync_result = await platform_service.sync_business_data(business)
                if sync_result.get("status") == "synced":
                    sync_count += 1
            except Exception as e:
                logging.error(f"Error syncing business {business.name} during setup: {e}")
        
        setup_results.append({
            "step": "business_sync",
            "status": "completed",
            "synced_businesses": sync_count,
            "total_businesses": len(businesses)
        })
        
        return {
            "message": "Centralized platform setup completed",
            "results": setup_results,
            "success": True,
            "next_steps": [
                "Configure delivery drivers in the centralized platform",
                "Set up order routing rules",
                "Configure notification webhooks"
            ]
        }
        
    except Exception as e:
        logging.error(f"Error setting up centralized platform: {e}")
        raise HTTPException(status_code=500, detail="Failed to set up centralized platform")
