"""
Driver model for delivery management with geospatial capabilities.
"""
from typing import Optional, List
from beanie import Document, PydanticObjectId, Indexed
from pydantic import BaseModel, Field, validator
from enum import Enum
from datetime import datetime
from pymongo import IndexModel, GEO2D


class DriverStatus(str, Enum):
    """Driver status enumeration."""
    OFFLINE = "offline"
    AVAILABLE = "available"
    BUSY = "busy"
    ON_BREAK = "on_break"
    UNAVAILABLE = "unavailable"


class VehicleType(str, Enum):
    """Vehicle type enumeration."""
    BICYCLE = "bicycle"
    MOTORCYCLE = "motorcycle"
    CAR = "car"
    SCOOTER = "scooter"
    WALKING = "walking"


class Location(BaseModel):
    """Geographic location with coordinates."""
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    address: Optional[str] = None
    updated_at: datetime = Field(default_factory=datetime.now)
    
    @property
    def coordinates(self) -> List[float]:
        """Return coordinates in [longitude, latitude] format for MongoDB."""
        return [self.longitude, self.latitude]


class DeliveryStats(BaseModel):
    """Driver delivery statistics."""
    total_deliveries: int = 0
    completed_deliveries: int = 0
    cancelled_deliveries: int = 0
    average_rating: float = 0.0
    total_earnings: float = 0.0
    total_distance_km: float = 0.0
    average_delivery_time_minutes: float = 0.0


class Driver(Document):
    """Driver model for delivery management."""
    
    # Basic Information
    driver_id: str = Field(..., description="Unique driver identifier")
    name: str = Field(..., min_length=1, max_length=100)
    phone: str = Field(..., min_length=10, max_length=15)
    email: Optional[str] = None
    
    # Status and Availability
    status: DriverStatus = Field(default=DriverStatus.OFFLINE)
    is_verified: bool = Field(default=False)
    is_active: bool = Field(default=True)
    
    # Vehicle Information
    vehicle_type: VehicleType = VehicleType.MOTORCYCLE
    vehicle_plate: Optional[str] = None
    vehicle_model: Optional[str] = None
    
    # Location (with geospatial index)
    current_location: Optional[Location] = None
    
    # Current Assignment
    current_order_id: Optional[PydanticObjectId] = None
    assigned_at: Optional[datetime] = None
    
    # Statistics
    stats: DeliveryStats = Field(default_factory=DeliveryStats)
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    last_active_at: Optional[datetime] = None
    
    # Service Area (optional - can be used for zone-based assignment)
    service_radius_km: float = Field(default=10.0, ge=1, le=50)
    preferred_zones: List[str] = Field(default_factory=list)
    
    class Settings:
        name = "drivers"
        indexes = [
            # Geospatial index for location-based queries
            IndexModel([("current_location.coordinates", GEO2D)]),
            
            # Compound indexes for efficient queries
            IndexModel([("status", 1), ("is_active", 1)]),
            IndexModel([("driver_id", 1)], unique=True),
            IndexModel([("phone", 1)], unique=True),
            
            # Performance indexes
            IndexModel([("created_at", -1)]),
            IndexModel([("last_active_at", -1)]),
        ]
    
    def update_location(self, latitude: float, longitude: float, address: Optional[str] = None):
        """Update driver's current location."""
        self.current_location = Location(
            latitude=latitude,
            longitude=longitude,
            address=address
        )
        self.updated_at = datetime.now()
        self.last_active_at = datetime.now()
    
    def set_status(self, status: DriverStatus):
        """Update driver status with timestamp."""
        self.status = status
        self.updated_at = datetime.now()
        
        if status == DriverStatus.AVAILABLE:
            self.last_active_at = datetime.now()
    
    def assign_order(self, order_id: PydanticObjectId):
        """Assign an order to the driver."""
        if self.status != DriverStatus.AVAILABLE:
            raise ValueError(f"Driver is not available (current status: {self.status})")
        
        self.current_order_id = order_id
        self.assigned_at = datetime.now()
        self.status = DriverStatus.BUSY
        self.updated_at = datetime.now()
    
    def complete_delivery(self, rating: Optional[float] = None, earnings: Optional[float] = None):
        """Mark delivery as completed and update stats."""
        if not self.current_order_id:
            raise ValueError("No active order to complete")
        
        # Update statistics
        self.stats.total_deliveries += 1
        self.stats.completed_deliveries += 1
        
        if earnings:
            self.stats.total_earnings += earnings
        
        if rating and rating > 0:
            # Calculate new average rating
            total_rated = self.stats.completed_deliveries
            if total_rated > 1:
                current_total = self.stats.average_rating * (total_rated - 1)
                self.stats.average_rating = (current_total + rating) / total_rated
            else:
                self.stats.average_rating = rating
        
        # Reset assignment
        self.current_order_id = None
        self.assigned_at = None
        self.status = DriverStatus.AVAILABLE
        self.updated_at = datetime.now()
        self.last_active_at = datetime.now()
    
    def cancel_delivery(self):
        """Cancel current delivery assignment."""
        if not self.current_order_id:
            raise ValueError("No active order to cancel")
        
        self.stats.cancelled_deliveries += 1
        self.current_order_id = None
        self.assigned_at = None
        self.status = DriverStatus.AVAILABLE
        self.updated_at = datetime.now()
    
    @property
    def is_available_for_assignment(self) -> bool:
        """Check if driver is available for new assignments."""
        return (
            self.is_active and 
            self.is_verified and 
            self.status == DriverStatus.AVAILABLE and
            self.current_order_id is None and
            self.current_location is not None
        )
    
    @property
    def success_rate(self) -> float:
        """Calculate delivery success rate."""
        if self.stats.total_deliveries == 0:
            return 0.0
        return (self.stats.completed_deliveries / self.stats.total_deliveries) * 100
    
    def to_dict(self) -> dict:
        """Convert driver to dictionary for API responses."""
        return {
            "id": str(self.id),
            "driver_id": self.driver_id,
            "name": self.name,
            "phone": self.phone,
            "email": self.email,
            "status": self.status,
            "is_verified": self.is_verified,
            "is_active": self.is_active,
            "vehicle_type": self.vehicle_type,
            "vehicle_plate": self.vehicle_plate,
            "current_location": self.current_location.dict() if self.current_location else None,
            "current_order_id": str(self.current_order_id) if self.current_order_id else None,
            "stats": self.stats.dict(),
            "success_rate": self.success_rate,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "last_active_at": self.last_active_at.isoformat() if self.last_active_at else None
        }
