"""
Driver service for managing driver assignments and finding nearest available drivers.
"""
from typing import List, Optional, Tuple
from datetime import datetime, timedelta
import logging
import math
from beanie import PydanticObjectId
from beanie.operators import And, Near

from ..models.driver import Driver, DriverStatus
from ..models.order import Order


class DriverService:
    """Service for driver management and assignment logic."""
    
    @staticmethod
    async def find_nearest_available_drivers(
        latitude: float,
        longitude: float,
        max_distance_km: float = 10.0,
        limit: int = 5
    ) -> List[Driver]:
        """
        Find nearest available drivers within specified distance.
        
        Args:
            latitude: Delivery latitude
            longitude: Delivery longitude 
            max_distance_km: Maximum search radius in kilometers
            limit: Maximum number of drivers to return
            
        Returns:
            List of available drivers sorted by distance
        """
        try:
            # Convert km to meters for MongoDB query
            max_distance_meters = max_distance_km * 1000
            
            # Query for available drivers near the location
            drivers = await Driver.find(
                And(
                    Driver.status == DriverStatus.AVAILABLE,
                    Driver.is_active == True,
                    Driver.is_verified == True,
                    Driver.current_order_id == None,
                    Driver.current_location != None
                )
            ).aggregate([
                {
                    "$geoNear": {
                        "near": {
                            "type": "Point",
                            "coordinates": [longitude, latitude]
                        },
                        "distanceField": "distance",
                        "maxDistance": max_distance_meters,
                        "spherical": True
                    }
                },
                {"$limit": limit}
            ]).to_list()
            
            logging.info(f"Found {len(drivers)} available drivers within {max_distance_km}km")
            return drivers
            
        except Exception as e:
            logging.error(f"Error finding nearest drivers: {e}")
            return []
    
    @staticmethod
    async def assign_nearest_driver(
        order: Order,
        max_distance_km: float = 15.0
    ) -> Optional[Driver]:
        """
        Find and assign the nearest available driver to an order.
        
        Args:
            order: Order to assign driver to
            max_distance_km: Maximum search radius
            
        Returns:
            Assigned driver or None if no available drivers
        """
        if not order.delivery_address or not order.delivery_address.latitude or not order.delivery_address.longitude:
            logging.warning(f"Order {order.order_number} has no valid delivery coordinates")
            return None
        
        try:
            # Find nearest available drivers
            drivers = await DriverService.find_nearest_available_drivers(
                latitude=order.delivery_address.latitude,
                longitude=order.delivery_address.longitude,
                max_distance_km=max_distance_km,
                limit=3  # Get top 3 candidates
            )
            
            if not drivers:
                logging.warning(f"No available drivers found for order {order.order_number}")
                return None
            
            # Select the best driver (for now, just the nearest)
            selected_driver = drivers[0]
            
            # Assign the order to the driver
            selected_driver.assign_order(order.id)
            await selected_driver.save()
            
            # Update order with driver assignment
            order.assigned_driver_id = selected_driver.id
            order.driver_assigned_at = datetime.now()
            await order.save()
            
            logging.info(f"Assigned driver {selected_driver.name} to order {order.order_number}")
            return selected_driver
            
        except Exception as e:
            logging.error(f"Error assigning driver to order {order.order_number}: {e}")
            return None
    
    @staticmethod
    async def get_driver_by_id(driver_id: PydanticObjectId) -> Optional[Driver]:
        """Get driver by ID."""
        try:
            return await Driver.get(driver_id)
        except Exception as e:
            logging.error(f"Error getting driver {driver_id}: {e}")
            return None
    
    @staticmethod
    async def update_driver_location(
        driver_id: PydanticObjectId,
        latitude: float,
        longitude: float,
        address: Optional[str] = None
    ) -> bool:
        """Update driver's current location."""
        try:
            driver = await Driver.get(driver_id)
            if not driver:
                return False
            
            driver.update_location(latitude, longitude, address)
            await driver.save()
            
            logging.info(f"Updated location for driver {driver.name}")
            return True
            
        except Exception as e:
            logging.error(f"Error updating driver location: {e}")
            return False
    
    @staticmethod
    async def set_driver_status(
        driver_id: PydanticObjectId,
        status: DriverStatus
    ) -> bool:
        """Update driver status."""
        try:
            driver = await Driver.get(driver_id)
            if not driver:
                return False
            
            driver.set_status(status)
            await driver.save()
            
            logging.info(f"Updated status for driver {driver.name} to {status}")
            return True
            
        except Exception as e:
            logging.error(f"Error updating driver status: {e}")
            return False
    
    @staticmethod
    async def complete_delivery(
        driver_id: PydanticObjectId,
        order_id: PydanticObjectId,
        rating: Optional[float] = None,
        earnings: Optional[float] = None
    ) -> bool:
        """Mark delivery as completed."""
        try:
            driver = await Driver.get(driver_id)
            if not driver or driver.current_order_id != order_id:
                return False
            
            driver.complete_delivery(rating, earnings)
            await driver.save()
            
            # Update order status
            order = await Order.get(order_id)
            if order:
                order.status = "delivered"
                order.delivered_at = datetime.now()
                await order.save()
            
            logging.info(f"Completed delivery for driver {driver.name}, order {order_id}")
            return True
            
        except Exception as e:
            logging.error(f"Error completing delivery: {e}")
            return False
    
    @staticmethod
    async def get_active_drivers_count() -> int:
        """Get count of currently active drivers."""
        try:
            return await Driver.find(
                And(
                    Driver.is_active == True,
                    Driver.status.in_([DriverStatus.AVAILABLE, DriverStatus.BUSY])
                )
            ).count()
        except Exception as e:
            logging.error(f"Error getting active drivers count: {e}")
            return 0
    
    @staticmethod
    async def get_available_drivers_in_area(
        center_lat: float,
        center_lon: float,
        radius_km: float = 20.0
    ) -> List[Driver]:
        """Get all available drivers in a specific area."""
        return await DriverService.find_nearest_available_drivers(
            latitude=center_lat,
            longitude=center_lon,
            max_distance_km=radius_km,
            limit=50  # Get more drivers for area overview
        )
    
    @staticmethod
    def calculate_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance between two points using Haversine formula."""
        # Convert to radians
        lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
        
        # Haversine formula
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
        c = 2 * math.asin(math.sqrt(a))
        
        # Earth's radius in kilometers
        earth_radius_km = 6371
        return earth_radius_km * c
    
    @staticmethod
    async def get_driver_performance_stats(driver_id: PydanticObjectId) -> dict:
        """Get comprehensive performance statistics for a driver."""
        try:
            driver = await Driver.get(driver_id)
            if not driver:
                return {}
            
            # Calculate additional stats
            today = datetime.now().date()
            week_ago = datetime.now() - timedelta(days=7)
            
            # Get recent orders for this driver
            recent_orders = await Order.find(
                And(
                    Order.assigned_driver_id == driver_id,
                    Order.created_at >= week_ago
                )
            ).to_list()
            
            weekly_deliveries = len([o for o in recent_orders if o.status == "delivered"])
            
            return {
                "driver_info": driver.to_dict(),
                "weekly_deliveries": weekly_deliveries,
                "recent_activity": len(recent_orders),
                "performance_score": driver.success_rate,
                "last_active": driver.last_active_at.isoformat() if driver.last_active_at else None
            }
            
        except Exception as e:
            logging.error(f"Error getting driver performance stats: {e}")
            return {}
