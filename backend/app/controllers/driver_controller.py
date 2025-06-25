"""
Driver management controller for driver operations.
"""
import logging
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from beanie import PydanticObjectId
from pydantic import BaseModel

from ..models.driver import Driver, DriverStatus, VehicleType, Location
from ..models.user import User
from ..services.auth_service import current_active_user
from ..services.driver_service import DriverService


class DriverCreateSchema(BaseModel):
    """Schema for creating a new driver."""
    driver_id: str
    name: str
    phone: str
    email: Optional[str] = None
    vehicle_type: VehicleType = VehicleType.MOTORCYCLE
    vehicle_plate: Optional[str] = None
    vehicle_model: Optional[str] = None


class DriverUpdateSchema(BaseModel):
    """Schema for updating driver information."""
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    vehicle_type: Optional[VehicleType] = None
    vehicle_plate: Optional[str] = None
    vehicle_model: Optional[str] = None
    is_active: Optional[bool] = None


class LocationUpdateSchema(BaseModel):
    """Schema for updating driver location."""
    latitude: float
    longitude: float
    address: Optional[str] = None


class DriverController:
    """Controller for driver management."""
    
    def __init__(self):
        self.router = APIRouter(prefix="/api/drivers", tags=["Drivers"])
        self._setup_routes()
    
    def _setup_routes(self):
        """Setup driver management routes."""
        
        @self.router.post("/", response_model=dict)
        async def create_driver(
            driver_data: DriverCreateSchema,
            current_user: User = Depends(current_active_user)
        ):
            """Create a new driver (admin only)."""
            try:
                # Check if driver ID or phone already exists
                existing = await Driver.find_one(
                    {"$or": [
                        {"driver_id": driver_data.driver_id},
                        {"phone": driver_data.phone}
                    ]}
                )
                if existing:
                    raise HTTPException(status_code=400, detail="Driver ID or phone already exists")
                
                # Create new driver
                driver = Driver(
                    driver_id=driver_data.driver_id,
                    name=driver_data.name,
                    phone=driver_data.phone,
                    email=driver_data.email,
                    vehicle_type=driver_data.vehicle_type,
                    vehicle_plate=driver_data.vehicle_plate,
                    vehicle_model=driver_data.vehicle_model
                )
                
                await driver.insert()
                
                logging.info(f"New driver created: {driver.name}")
                return driver.to_dict()
                
            except Exception as e:
                logging.error(f"Error creating driver: {e}")
                raise HTTPException(status_code=500, detail="Failed to create driver")
        
        @self.router.get("/", response_model=List[dict])
        async def get_drivers(
            status: Optional[DriverStatus] = Query(None, description="Filter by status"),
            is_active: Optional[bool] = Query(None, description="Filter by active status"),
            limit: int = Query(50, ge=1, le=100),
            skip: int = Query(0, ge=0),
            current_user: User = Depends(current_active_user)
        ):
            """Get list of drivers."""
            try:
                # Build query
                query_filter = {}
                if status:
                    query_filter["status"] = status
                if is_active is not None:
                    query_filter["is_active"] = is_active
                
                drivers = await Driver.find(query_filter).skip(skip).limit(limit).to_list()
                
                return [driver.to_dict() for driver in drivers]
                
            except Exception as e:
                logging.error(f"Error getting drivers: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.get("/available")
        async def get_available_drivers(
            latitude: float = Query(..., description="Search center latitude"),
            longitude: float = Query(..., description="Search center longitude"),
            radius_km: float = Query(10.0, ge=1, le=50, description="Search radius in km"),
            current_user: User = Depends(current_active_user)
        ):
            """Get available drivers in a specific area."""
            try:
                drivers = await DriverService.find_nearest_available_drivers(
                    latitude=latitude,
                    longitude=longitude,
                    max_distance_km=radius_km,
                    limit=20
                )
                
                return [driver.to_dict() for driver in drivers]
                
            except Exception as e:
                logging.error(f"Error getting available drivers: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.get("/{driver_id}")
        async def get_driver(
            driver_id: str,
            current_user: User = Depends(current_active_user)
        ):
            """Get a specific driver."""
            try:
                driver_obj_id = PydanticObjectId(driver_id)
                driver = await Driver.get(driver_obj_id)
                
                if not driver:
                    raise HTTPException(status_code=404, detail="Driver not found")
                
                return driver.to_dict()
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid driver ID")
            except Exception as e:
                logging.error(f"Error getting driver: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.patch("/{driver_id}/location")
        async def update_driver_location(
            driver_id: str,
            location_data: LocationUpdateSchema,
            current_user: User = Depends(current_active_user)
        ):
            """Update driver's current location."""
            try:
                driver_obj_id = PydanticObjectId(driver_id)
                
                success = await DriverService.update_driver_location(
                    driver_obj_id,
                    location_data.latitude,
                    location_data.longitude,
                    location_data.address
                )
                
                if not success:
                    raise HTTPException(status_code=404, detail="Driver not found")
                
                return {"message": "Location updated successfully"}
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid driver ID")
            except Exception as e:
                logging.error(f"Error updating driver location: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.patch("/{driver_id}/status")
        async def update_driver_status(
            driver_id: str,
            status: DriverStatus,
            current_user: User = Depends(current_active_user)
        ):
            """Update driver status."""
            try:
                driver_obj_id = PydanticObjectId(driver_id)
                
                success = await DriverService.set_driver_status(driver_obj_id, status)
                
                if not success:
                    raise HTTPException(status_code=404, detail="Driver not found")
                
                return {"message": f"Status updated to {status}"}
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid driver ID")
            except Exception as e:
                logging.error(f"Error updating driver status: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.get("/stats/dashboard")
        async def get_driver_dashboard_stats(
            current_user: User = Depends(current_active_user)
        ):
            """Get dashboard statistics for drivers."""
            try:
                # Get counts by status
                total_drivers = await Driver.find().count()
                active_drivers = await DriverService.get_active_drivers_count()
                available_drivers = await Driver.find(
                    {"status": DriverStatus.AVAILABLE, "is_active": True}
                ).count()
                busy_drivers = await Driver.find(
                    {"status": DriverStatus.BUSY, "is_active": True}
                ).count()
                
                return {
                    "total_drivers": total_drivers,
                    "active_drivers": active_drivers,
                    "available_drivers": available_drivers,
                    "busy_drivers": busy_drivers,
                    "offline_drivers": total_drivers - active_drivers
                }
                
            except Exception as e:
                logging.error(f"Error getting driver dashboard stats: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")


# Create controller instance
driver_controller = DriverController()
