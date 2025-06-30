"""
Integration service for communicating with the centralized delivery platform.
This service handles sending order updates to the main platform that manages drivers.
"""
import logging
import aiohttp
import json
from typing import Optional, Dict, Any, List
from datetime import datetime

from ..models.order import Order, OrderStatus
from ..models.business import Business
from ..core.config import config


class CentralizedPlatformService:
    """Service for integrating with the centralized delivery platform."""
    
    def __init__(self):
        # Access centralized platform configuration
        self.platform_base_url = config.centralized_platform.centralized_platform_url
        self.api_key = config.centralized_platform.centralized_platform_api_key
        self.webhook_secret = config.centralized_platform.centralized_platform_webhook_secret
        self.timeout = config.centralized_platform.platform_timeout
        self.retry_attempts = config.centralized_platform.platform_retry_attempts
        
        # Platform specific configuration
        self.platform_app_name = getattr(config.centralized_platform, 'platform_app_name', None)
        
    def _get_headers(self) -> Dict[str, str]:
        """Get common headers for platform API requests."""
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-Platform-Source": "order-receiver-app"
        }
    
    async def test_connection(self) -> Dict[str, Any]:
        """Test connection to the delivery platform."""
        try:
            headers = self._get_headers()
            
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    f"{self.platform_base_url}/account",
                    headers=headers,
                    timeout=self.timeout
                ) as response:
                    if response.status == 200:
                        account_info = await response.json()
                        logging.info("Successfully connected to delivery platform")
                        return {
                            "status": "connected",
                            "platform": "delivery_service",
                            "account": account_info.get("email", "Unknown"),
                            "timestamp": datetime.now().isoformat()
                        }
                    else:
                        error_text = await response.text()
                        logging.error(f"Failed to connect to delivery platform. Status: {response.status}")
                        return {
                            "status": "failed",
                            "error": f"HTTP {response.status}: {error_text}",
                            "timestamp": datetime.now().isoformat()
                        }
                        
        except Exception as e:
            logging.error(f"Error testing delivery platform connection: {e}")
            return {
                "status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    async def get_platform_apps(self) -> List[Dict[str, Any]]:
        """Get list of apps from the delivery platform."""
        try:
            headers = self._get_headers()
            
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    f"{self.platform_base_url}/apps",
                    headers=headers,
                    timeout=self.timeout
                ) as response:
                    if response.status == 200:
                        apps = await response.json()
                        logging.info(f"Retrieved {len(apps)} apps from delivery platform")
                        return apps
                    else:
                        error_text = await response.text()
                        logging.error(f"Failed to get apps from delivery platform. Status: {response.status}")
                        return []
                        
        except Exception as e:
            logging.error(f"Error getting apps from delivery platform: {e}")
            return []
    
    async def deploy_centralized_app(self, app_config: Dict[str, Any]) -> Dict[str, Any]:
        """Deploy or update the centralized platform app."""
        try:
            headers = self._get_headers()
            
            # Create or update app configuration
            app_data = {
                "name": app_config.get("name", "delivery-platform-central"),
                "region": app_config.get("region", "us"),
                "stack": app_config.get("stack", "production"),
                "buildpacks": [
                    {"url": "python"},
                    {"url": "nodejs"}
                ]
            }
            
            async with aiohttp.ClientSession() as session:
                # Try to create new app
                async with session.post(
                    f"{self.platform_base_url}/apps",
                    json=app_data,
                    headers=headers,
                    timeout=self.timeout
                ) as response:
                    if response.status in [200, 201]:
                        app_info = await response.json()
                        logging.info(f"Successfully deployed app: {app_info.get('name')}")
                        return {
                            "status": "deployed",
                            "app": app_info,
                            "timestamp": datetime.now().isoformat()
                        }
                    elif response.status == 422:  # App already exists
                        # Try to update existing app
                        app_name = app_data["name"]
                        async with session.patch(
                            f"{self.platform_base_url}/apps/{app_name}",
                            json={"buildpacks": app_data["buildpacks"]},
                            headers=headers,
                            timeout=self.timeout
                        ) as update_response:
                            if update_response.status == 200:
                                app_info = await update_response.json()
                                logging.info(f"Successfully updated existing app: {app_name}")
                                return {
                                    "status": "updated",
                                    "app": app_info,
                                    "timestamp": datetime.now().isoformat()
                                }
                    
                    error_text = await response.text()
                    logging.error(f"Failed to deploy app. Status: {response.status}, Error: {error_text}")
                    return {
                        "status": "failed",
                        "error": f"HTTP {response.status}: {error_text}",
                        "timestamp": datetime.now().isoformat()
                    }
                        
        except Exception as e:
            logging.error(f"Error deploying app to delivery platform: {e}")
            return {
                "status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    async def sync_business_data(self, business: Business) -> Dict[str, Any]:
        """Sync business data to the centralized platform."""
        try:
            # First, ensure we have a target app
            if not self.platform_app_name:
                logging.warning("No platform app name configured for data sync")
                return {"status": "no_target_app", "message": "Configure PLATFORM_APP_NAME"}
            
            headers = self._get_headers()
            
            # Prepare business data for sync
            business_data = {
                "business_id": str(business.id),
                "name": business.name,
                "type": business.business_type,
                "address": {
                    "street": business.address.street if business.address else None,
                    "city": business.address.city if business.address else None,
                    "district": business.address.district if business.address else None,
                    "latitude": business.address.latitude if business.address else None,
                    "longitude": business.address.longitude if business.address else None
                } if business.address else None,
                "contact": {
                    "phone": business.phone,
                    "email": business.email
                },
                "settings": {
                    "delivery_radius": getattr(business, 'delivery_radius', 5),
                    "average_prep_time": getattr(business, 'average_prep_time', 30),
                    "is_active": getattr(business, 'is_active', True)
                },
                "sync_timestamp": datetime.now().isoformat()
            }
            
            # Set environment variable on the target app with business data
            env_var_name = f"BUSINESS_{str(business.id).replace('-', '_').upper()}"
            config_data = {
                env_var_name: json.dumps(business_data)
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.patch(
                    f"{self.platform_base_url}/apps/{self.platform_app_name}/config-vars",
                    json=config_data,
                    headers=headers,
                    timeout=self.timeout
                ) as response:
                    if response.status == 200:
                        logging.info(f"Successfully synced business {business.name} to centralized platform")
                        return {
                            "status": "synced",
                            "business_id": str(business.id),
                            "timestamp": datetime.now().isoformat()
                        }
                    else:
                        error_text = await response.text()
                        logging.error(f"Failed to sync business data. Status: {response.status}")
                        return {
                            "status": "failed",
                            "error": f"HTTP {response.status}: {error_text}",
                            "timestamp": datetime.now().isoformat()
                        }
                        
        except Exception as e:
            logging.error(f"Error syncing business data: {e}")
            return {
                "status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    async def notify_order_status_change(
        self, 
        order: Order, 
        business: Business,
        new_status: OrderStatus,
        notes: Optional[str] = None
    ) -> bool:
        """
        Notify the centralized platform about order status changes.
        This allows the platform to handle driver assignment/management.
        """
        try:
            # For platform integration, we'll use config vars to store order updates
            if not self.platform_app_name:
                logging.warning("No platform app name configured for order notifications")
                return False
            
            headers = self._get_headers()
            
            # Create order status payload
            order_data = {
                "order_id": str(order.id),
                "order_number": order.order_number,
                "business_id": str(order.business_id),
                "business_name": business.name,
                "status": new_status.value,
                "updated_at": datetime.now().isoformat(),
                "notes": notes,
                "delivery_address": {
                    "latitude": order.delivery_address.latitude if order.delivery_address else None,
                    "longitude": order.delivery_address.longitude if order.delivery_address else None,
                    "street": order.delivery_address.street if order.delivery_address else None,
                    "city": order.delivery_address.city if order.delivery_address else None,
                    "district": order.delivery_address.district if order.delivery_address else None
                } if order.delivery_address else None,
                "estimated_ready_time": order.estimated_ready_time.isoformat() if order.estimated_ready_time else None,
                "customer_info": {
                    "name": order.customer_name,
                    "phone": order.customer_phone
                }
            }
            
            # Store order update as environment variable
            env_var_name = f"ORDER_UPDATE_{str(order.id).replace('-', '_').upper()}"
            config_data = {
                env_var_name: json.dumps(order_data)
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.patch(
                    f"{self.platform_base_url}/apps/{self.platform_app_name}/config-vars",
                    json=config_data,
                    headers=headers,
                    timeout=self.timeout
                ) as response:
                    if response.status == 200:
                        logging.info(f"Successfully notified centralized platform about order {order.order_number} status: {new_status}")
                        return True
                    else:
                        error_text = await response.text()
                        logging.error(f"Failed to notify centralized platform. Status: {response.status}, Error: {error_text}")
                        return False
                        
        except Exception as e:
            logging.error(f"Error notifying centralized platform about order {order.order_number}: {e}")
            return False
    
    async def notify_order_confirmed(self, order: Order, business: Business, notes: Optional[str] = None) -> bool:
        """
        Notify centralized platform that order is confirmed and ready for driver assignment.
        The platform will handle finding and assigning the nearest available driver.
        """
        logging.info(f"Notifying centralized platform that order {order.order_number} is confirmed for driver assignment")
        return await self.notify_order_status_change(order, business, OrderStatus.CONFIRMED, notes)
    
    async def notify_order_ready(self, order: Order, business: Business, notes: Optional[str] = None) -> bool:
        """
        Notify centralized platform that order is ready for pickup by driver.
        """
        logging.info(f"Notifying centralized platform that order {order.order_number} is ready for pickup")
        return await self.notify_order_status_change(order, business, OrderStatus.READY, notes)
    
    async def notify_order_cancelled(self, order: Order, business: Business, reason: str) -> bool:
        """
        Notify centralized platform that order was cancelled by merchant.
        Platform can handle driver notification and reassignment.
        """
        logging.info(f"Notifying centralized platform that order {order.order_number} was cancelled")
        return await self.notify_order_status_change(order, business, OrderStatus.CANCELLED, reason)
    
    async def receive_driver_assignment_webhook(self, webhook_data: Dict[str, Any]) -> bool:
        """
        Handle incoming webhook from centralized platform when a driver is assigned.
        """
        try:
            order_id = webhook_data.get("order_id")
            driver_info = webhook_data.get("driver_info", {})
            
            if not order_id:
                logging.error("No order_id in driver assignment webhook")
                return False
            
            # Update order with driver assignment info
            from ..models.order import Order
            order = await Order.get(order_id)
            if not order:
                logging.error(f"Order {order_id} not found for driver assignment")
                return False
            
            # Store driver info (but not manage the driver directly)
            order.assigned_driver_info = {
                "driver_id": driver_info.get("driver_id"),
                "driver_name": driver_info.get("name"),
                "driver_phone": driver_info.get("phone"),
                "vehicle_type": driver_info.get("vehicle_type"),
                "estimated_pickup_time": driver_info.get("estimated_pickup_time")
            }
            order.driver_assigned_at = datetime.now()
            order.status = OrderStatus.OUT_FOR_DELIVERY
            
            await order.save()
            
            logging.info(f"Driver {driver_info.get('name')} assigned to order {order.order_number} by centralized platform")
            return True
            
        except Exception as e:
            logging.error(f"Error processing driver assignment webhook: {e}")
            return False
    
    async def health_check(self) -> bool:
        """Check if centralized platform is reachable."""
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    f"{self.platform_base_url}/health",
                    timeout=5
                ) as response:
                    return response.status == 200
        except Exception:
            return False


# Global service instance
centralized_platform_service = CentralizedPlatformService()
