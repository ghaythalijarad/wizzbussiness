"""
Customer notification service for sending real-time updates to customer apps.
This integrates with the centralized platform to provide order tracking and notifications.
"""
import logging
import aiohttp
from typing import Optional, Dict, Any, List
from datetime import datetime
from enum import Enum

from ..models.order import Order, OrderStatus
from ..models.business import Business
from ..core.config import config


class NotificationType(str, Enum):
    """Types of customer notifications."""
    ORDER_CONFIRMED = "order_confirmed"
    ORDER_PREPARING = "order_preparing" 
    ORDER_READY = "order_ready"
    DRIVER_ASSIGNED = "driver_assigned"
    ORDER_PICKED_UP = "order_picked_up"
    ORDER_OUT_FOR_DELIVERY = "order_out_for_delivery"
    ORDER_DELIVERED = "order_delivered"
    ORDER_CANCELLED = "order_cancelled"
    ESTIMATED_TIME_UPDATE = "estimated_time_update"


class CustomerNotificationService:
    """Service for sending notifications to customer apps via centralized platform."""
    
    def __init__(self):
        # Access centralized platform configuration
        self.platform_base_url = config.centralized_platform.centralized_platform_url
        self.api_key = config.centralized_platform.centralized_platform_api_key
        self.service_name = "order-receiver-app"
    
    async def send_customer_notification(
        self,
        order: Order,
        business: Business,
        notification_type: NotificationType,
        message: str,
        additional_data: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Send notification to customer app via centralized platform.
        """
        try:
            payload = {
                "notification_type": notification_type.value,
                "order_id": str(order.id),
                "order_number": order.order_number,
                "customer_info": {
                    "customer_id": order.customer_id,
                    "customer_name": order.customer_name,
                    "customer_phone": order.customer_phone,
                    "customer_email": order.customer_email
                },
                "business_info": {
                    "business_id": str(order.business_id),
                    "business_name": business.name,
                    "business_type": business.business_type,
                    "business_address": business.address.dict() if business.address else None
                },
                "order_details": {
                    "status": order.status,
                    "total_amount": order.total_amount,
                    "delivery_type": order.delivery_type,
                    "estimated_delivery_time": order.estimated_delivery_time.isoformat() if order.estimated_delivery_time else None,
                    "estimated_ready_time": order.estimated_ready_time.isoformat() if order.estimated_ready_time else None
                },
                "message": message,
                "timestamp": datetime.now().isoformat(),
                "source": self.service_name,
                "additional_data": additional_data or {}
            }
            
            # Add driver info if available
            if order.assigned_driver_info:
                payload["driver_info"] = {
                    "driver_id": order.assigned_driver_info.get("driver_id"),
                    "driver_name": order.assigned_driver_info.get("driver_name"),
                    "driver_phone": order.assigned_driver_info.get("driver_phone"),
                    "vehicle_type": order.assigned_driver_info.get("vehicle_type"),
                    "estimated_arrival": order.assigned_driver_info.get("estimated_pickup_time")
                }
            
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
                "X-Service-Source": self.service_name
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.platform_base_url}/notifications/customer",
                    json=payload,
                    headers=headers,
                    timeout=10
                ) as response:
                    if response.status == 200:
                        logging.info(f"Successfully sent {notification_type} notification to customer for order {order.order_number}")
                        return True
                    else:
                        error_text = await response.text()
                        logging.error(f"Failed to send customer notification. Status: {response.status}, Error: {error_text}")
                        return False
                        
        except aiohttp.ClientTimeout:
            logging.error(f"Timeout while sending customer notification for order {order.order_number}")
            return False
        except Exception as e:
            logging.error(f"Error sending customer notification for order {order.order_number}: {e}")
            return False
    
    async def notify_order_confirmed(
        self,
        order: Order,
        business: Business,
        notes: Optional[str] = None
    ) -> bool:
        """Notify customer that their order has been confirmed by the merchant."""
        message = f"Great news! {business.name} has confirmed your order #{order.order_number}"
        if order.estimated_ready_time:
            message += f" and it will be ready by {order.estimated_ready_time.strftime('%H:%M')}"
        
        additional_data = {
            "preparation_time_minutes": order.preparation_time_minutes,
            "business_notes": notes
        }
        
        return await self.send_customer_notification(
            order, business, NotificationType.ORDER_CONFIRMED, message, additional_data
        )
    
    async def notify_order_preparing(
        self,
        order: Order,
        business: Business,
        estimated_ready_time: Optional[datetime] = None
    ) -> bool:
        """Notify customer that their order is being prepared."""
        message = f"{business.name} is now preparing your order #{order.order_number}"
        if estimated_ready_time:
            message += f". It will be ready by {estimated_ready_time.strftime('%H:%M')}"
        
        additional_data = {
            "estimated_ready_time": estimated_ready_time.isoformat() if estimated_ready_time else None
        }
        
        return await self.send_customer_notification(
            order, business, NotificationType.ORDER_PREPARING, message, additional_data
        )
    
    async def notify_order_ready(
        self,
        order: Order,
        business: Business
    ) -> bool:
        """Notify customer that their order is ready for pickup/delivery."""
        if order.delivery_type == "pickup":
            message = f"Your order #{order.order_number} is ready for pickup at {business.name}!"
        else:
            message = f"Your order #{order.order_number} is ready! A driver will pick it up soon."
        
        return await self.send_customer_notification(
            order, business, NotificationType.ORDER_READY, message
        )
    
    async def notify_driver_assigned(
        self,
        order: Order,
        business: Business,
        driver_info: Dict[str, Any]
    ) -> bool:
        """Notify customer that a driver has been assigned to their order."""
        driver_name = driver_info.get("driver_name", "A driver")
        message = f"{driver_name} has been assigned to deliver your order #{order.order_number}"
        
        additional_data = {
            "driver_info": driver_info,
            "tracking_available": True
        }
        
        return await self.send_customer_notification(
            order, business, NotificationType.DRIVER_ASSIGNED, message, additional_data
        )
    
    async def notify_order_picked_up(
        self,
        order: Order,
        business: Business,
        driver_info: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Notify customer that their order has been picked up by the driver."""
        driver_name = driver_info.get("driver_name", "Your driver") if driver_info else "Your driver"
        message = f"{driver_name} has picked up your order #{order.order_number} and is on the way!"
        
        additional_data = {
            "driver_info": driver_info,
            "tracking_url": f"{self.platform_base_url}/track/{order.order_number}",
            "estimated_delivery": order.estimated_delivery_time.isoformat() if order.estimated_delivery_time else None
        }
        
        return await self.send_customer_notification(
            order, business, NotificationType.ORDER_PICKED_UP, message, additional_data
        )
    
    async def notify_order_out_for_delivery(
        self,
        order: Order,
        business: Business,
        estimated_arrival: Optional[datetime] = None
    ) -> bool:
        """Notify customer that their order is out for delivery."""
        message = f"Your order #{order.order_number} is out for delivery"
        if estimated_arrival:
            message += f" and will arrive by {estimated_arrival.strftime('%H:%M')}"
        
        additional_data = {
            "tracking_url": f"{self.platform_base_url}/track/{order.order_number}",
            "estimated_arrival": estimated_arrival.isoformat() if estimated_arrival else None
        }
        
        return await self.send_customer_notification(
            order, business, NotificationType.ORDER_OUT_FOR_DELIVERY, message, additional_data
        )
    
    async def notify_order_delivered(
        self,
        order: Order,
        business: Business,
        delivery_notes: Optional[str] = None
    ) -> bool:
        """Notify customer that their order has been delivered."""
        message = f"Your order #{order.order_number} has been delivered! Enjoy your meal!"
        
        additional_data = {
            "delivery_time": datetime.now().isoformat(),
            "delivery_notes": delivery_notes,
            "rating_requested": True
        }
        
        return await self.send_customer_notification(
            order, business, NotificationType.ORDER_DELIVERED, message, additional_data
        )
    
    async def notify_order_cancelled(
        self,
        order: Order,
        business: Business,
        reason: str,
        refund_info: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Notify customer that their order has been cancelled."""
        message = f"Unfortunately, your order #{order.order_number} from {business.name} has been cancelled"
        if reason:
            message += f". Reason: {reason}"
        
        additional_data = {
            "cancellation_reason": reason,
            "refund_info": refund_info,
            "cancelled_at": datetime.now().isoformat()
        }
        
        return await self.send_customer_notification(
            order, business, NotificationType.ORDER_CANCELLED, message, additional_data
        )
    
    async def notify_estimated_time_update(
        self,
        order: Order,
        business: Business,
        new_estimated_time: datetime,
        delay_reason: Optional[str] = None
    ) -> bool:
        """Notify customer about updates to estimated delivery time."""
        message = f"Update: Your order #{order.order_number} estimated time has been updated to {new_estimated_time.strftime('%H:%M')}"
        if delay_reason:
            message += f". {delay_reason}"
        
        additional_data = {
            "new_estimated_time": new_estimated_time.isoformat(),
            "delay_reason": delay_reason,
            "updated_at": datetime.now().isoformat()
        }
        
        return await self.send_customer_notification(
            order, business, NotificationType.ESTIMATED_TIME_UPDATE, message, additional_data
        )
    
    async def send_push_notification(
        self,
        customer_device_tokens: List[str],
        title: str,
        body: str,
        data: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Send push notification directly to customer devices.
        This would be used for immediate notifications.
        """
        try:
            payload = {
                "device_tokens": customer_device_tokens,
                "notification": {
                    "title": title,
                    "body": body
                },
                "data": data or {},
                "priority": "high"
            }
            
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.platform_base_url}/notifications/push",
                    json=payload,
                    headers=headers,
                    timeout=10
                ) as response:
                    return response.status == 200
                    
        except Exception as e:
            logging.error(f"Error sending push notification: {e}")
            return False
    
    async def get_customer_tracking_info(self, order_id: str) -> Optional[Dict[str, Any]]:
        """Get real-time tracking information for a customer's order."""
        try:
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    f"{self.platform_base_url}/tracking/{order_id}",
                    headers=headers,
                    timeout=10
                ) as response:
                    if response.status == 200:
                        return await response.json()
                    return None
                    
        except Exception as e:
            logging.error(f"Error getting tracking info: {e}")
            return None


# Global instance
customer_notification_service = CustomerNotificationService()
