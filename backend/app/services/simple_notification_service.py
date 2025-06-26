"""
Simplified Notification Service for Heroku Deployment
====================================================

This is a simplified version of the notification system designed for easier Heroku deployment.
It removes WebSocket complexity and focuses on HTTP-based notifications and local notifications.

Key simplifications:
1. HTTP-based instead of WebSocket real-time connections
2. Database-persisted notifications instead of in-memory storage
3. Polling-based updates instead of push notifications
4. Simplified notification types and priorities
"""
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
from enum import Enum
from beanie import PydanticObjectId, Document
from pydantic import BaseModel

from ..models.user import User
from ..models.business import Business
from ..models.order import Order, OrderStatus


class SimpleNotificationType(str, Enum):
    """Simplified notification types."""
    NEW_ORDER = "new_order"
    ORDER_UPDATE = "order_update"
    SYSTEM_MESSAGE = "system_message"


class SimpleNotificationPriority(str, Enum):
    """Simplified notification priority levels."""
    NORMAL = "normal"
    HIGH = "high"


class SimpleNotification(Document):
    """Database model for simplified notifications."""
    
    business_id: str
    notification_type: SimpleNotificationType
    title: str
    message: str
    data: Optional[Dict[str, Any]] = {}
    priority: SimpleNotificationPriority = SimpleNotificationPriority.NORMAL
    is_read: bool = False
    created_at: datetime
    expires_at: Optional[datetime] = None
    
    class Settings:
        name = "simple_notifications"
        indexes = [
            "business_id",
            "created_at",
            "is_read",
            [("business_id", 1), ("created_at", -1)],
            [("business_id", 1), ("is_read", 1)],
        ]


class SimpleNotificationService:
    """Simplified notification service for Heroku deployment."""
    
    def __init__(self):
        self.max_notifications_per_business = 100
        self.notification_retention_days = 7
    
    async def send_new_order_notification(self, order: Order, business: Business) -> bool:
        """Send notification for a new order."""
        try:
            notification = SimpleNotification(
                business_id=str(business.id),
                notification_type=SimpleNotificationType.NEW_ORDER,
                title="🔔 New Order Received!",
                message=f"Order #{order.order_number} from {order.customer_name} - ${order.total_amount:.2f}",
                data={
                    "order_id": str(order.id),
                    "order_number": order.order_number,
                    "customer_name": order.customer_name,
                    "total_amount": order.total_amount,
                    "items_count": len(order.items) if order.items else 0,
                },
                priority=SimpleNotificationPriority.HIGH,
                created_at=datetime.utcnow(),
                expires_at=datetime.utcnow() + timedelta(days=self.notification_retention_days)
            )
            
            await notification.save()
            await self._cleanup_old_notifications(str(business.id))
            
            logging.info(f"New order notification sent for order {order.order_number}")
            return True
            
        except Exception as e:
            logging.error(f"Error sending new order notification: {e}")
            return False
    
    async def send_order_update_notification(
        self, 
        order: Order, 
        business: Business, 
        status: OrderStatus,
        custom_message: Optional[str] = None
    ) -> bool:
        """Send notification for order status update."""
        try:
            status_messages = {
                OrderStatus.CONFIRMED: f"Order #{order.order_number} has been confirmed",
                OrderStatus.PREPARING: f"Order #{order.order_number} is being prepared",
                OrderStatus.READY: f"Order #{order.order_number} is ready for pickup/delivery",
                OrderStatus.OUT_FOR_DELIVERY: f"Order #{order.order_number} is out for delivery",
                OrderStatus.DELIVERED: f"Order #{order.order_number} has been delivered",
                OrderStatus.CANCELLED: f"Order #{order.order_number} has been cancelled",
            }
            
            message = custom_message or status_messages.get(status, f"Order #{order.order_number} status updated")
            
            notification = SimpleNotification(
                business_id=str(business.id),
                notification_type=SimpleNotificationType.ORDER_UPDATE,
                title="📦 Order Update",
                message=message,
                data={
                    "order_id": str(order.id),
                    "order_number": order.order_number,
                    "customer_name": order.customer_name,
                    "old_status": order.status,
                    "new_status": status.value,
                },
                priority=SimpleNotificationPriority.NORMAL,
                created_at=datetime.utcnow(),
                expires_at=datetime.utcnow() + timedelta(days=self.notification_retention_days)
            )
            
            await notification.save()
            await self._cleanup_old_notifications(str(business.id))
            
            logging.info(f"Order update notification sent for order {order.order_number}")
            return True
            
        except Exception as e:
            logging.error(f"Error sending order update notification: {e}")
            return False
    
    async def send_system_message(
        self, 
        business_id: str, 
        title: str, 
        message: str, 
        data: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Send a system message notification."""
        try:
            notification = SimpleNotification(
                business_id=business_id,
                notification_type=SimpleNotificationType.SYSTEM_MESSAGE,
                title=title,
                message=message,
                data=data or {},
                priority=SimpleNotificationPriority.NORMAL,
                created_at=datetime.utcnow(),
                expires_at=datetime.utcnow() + timedelta(days=self.notification_retention_days)
            )
            
            await notification.save()
            await self._cleanup_old_notifications(business_id)
            
            logging.info(f"System message sent to business {business_id}: {title}")
            return True
            
        except Exception as e:
            logging.error(f"Error sending system message: {e}")
            return False
    
    async def get_notifications(
        self, 
        business_id: str, 
        limit: int = 50, 
        unread_only: bool = False
    ) -> List[Dict[str, Any]]:
        """Get notifications for a business via HTTP polling."""
        try:
            business_obj_id = PydanticObjectId(business_id)
            
            # Build query
            query = {"business_id": business_id}
            if unread_only:
                query["is_read"] = False
            
            # Get notifications sorted by creation date (newest first)
            notifications = await SimpleNotification.find(query).sort(-SimpleNotification.created_at).limit(limit).to_list()
            
            return [
                {
                    "id": str(notif.id),
                    "type": notif.notification_type,
                    "title": notif.title,
                    "message": notif.message,
                    "data": notif.data,
                    "priority": notif.priority,
                    "is_read": notif.is_read,
                    "created_at": notif.created_at.isoformat(),
                    "expires_at": notif.expires_at.isoformat() if notif.expires_at else None,
                }
                for notif in notifications
            ]
            
        except Exception as e:
            logging.error(f"Error getting notifications for business {business_id}: {e}")
            return []
    
    async def mark_notification_read(self, business_id: str, notification_id: str) -> bool:
        """Mark a notification as read."""
        try:
            notification = await SimpleNotification.find_one({
                "business_id": business_id,
                "_id": PydanticObjectId(notification_id)
            })
            
            if notification:
                notification.is_read = True
                await notification.save()
                logging.info(f"Notification {notification_id} marked as read")
                return True
            else:
                logging.warning(f"Notification {notification_id} not found for business {business_id}")
                return False
                
        except Exception as e:
            logging.error(f"Error marking notification as read: {e}")
            return False
    
    async def mark_all_read(self, business_id: str) -> bool:
        """Mark all notifications as read for a business."""
        try:
            await SimpleNotification.find({"business_id": business_id, "is_read": False}).update_many({"$set": {"is_read": True}})
            logging.info(f"All notifications marked as read for business {business_id}")
            return True
            
        except Exception as e:
            logging.error(f"Error marking all notifications as read: {e}")
            return False
    
    async def get_unread_count(self, business_id: str) -> int:
        """Get count of unread notifications for a business."""
        try:
            count = await SimpleNotification.count_documents({
                "business_id": business_id,
                "is_read": False
            })
            return count
            
        except Exception as e:
            logging.error(f"Error getting unread count: {e}")
            return 0
    
    async def delete_notification(self, business_id: str, notification_id: str) -> bool:
        """Delete a specific notification."""
        try:
            result = await SimpleNotification.find_one({
                "business_id": business_id,
                "_id": PydanticObjectId(notification_id)
            }).delete()
            
            if result:
                logging.info(f"Notification {notification_id} deleted")
                return True
            else:
                logging.warning(f"Notification {notification_id} not found")
                return False
                
        except Exception as e:
            logging.error(f"Error deleting notification: {e}")
            return False
    
    async def cleanup_expired_notifications(self) -> int:
        """Clean up expired notifications across all businesses."""
        try:
            now = datetime.utcnow()
            result = await SimpleNotification.find({
                "expires_at": {"$lt": now}
            }).delete()
            
            count = result.deleted_count if hasattr(result, 'deleted_count') else 0
            logging.info(f"Cleaned up {count} expired notifications")
            return count
            
        except Exception as e:
            logging.error(f"Error cleaning up expired notifications: {e}")
            return 0
    
    async def _cleanup_old_notifications(self, business_id: str):
        """Keep only the most recent notifications per business."""
        try:
            # Count notifications for this business
            count = await SimpleNotification.count_documents({"business_id": business_id})
            
            if count > self.max_notifications_per_business:
                # Get IDs of oldest notifications to delete
                excess_count = count - self.max_notifications_per_business
                oldest_notifications = await SimpleNotification.find(
                    {"business_id": business_id}
                ).sort(SimpleNotification.created_at).limit(excess_count).to_list()
                
                # Delete oldest notifications
                for notification in oldest_notifications:
                    await notification.delete()
                
                logging.info(f"Cleaned up {excess_count} old notifications for business {business_id}")
                
        except Exception as e:
            logging.error(f"Error cleaning up old notifications: {e}")
    
    async def get_service_stats(self) -> Dict[str, Any]:
        """Get service statistics (for monitoring)."""
        try:
            total_notifications = await SimpleNotification.count_documents({})
            unread_notifications = await SimpleNotification.count_documents({"is_read": False})
            
            # Get notifications by type
            pipeline = [
                {"$group": {"_id": "$notification_type", "count": {"$sum": 1}}}
            ]
            type_stats = await SimpleNotification.aggregate(pipeline).to_list()
            
            # Get notifications by business (top 10)
            business_pipeline = [
                {"$group": {"_id": "$business_id", "count": {"$sum": 1}}},
                {"$sort": {"count": -1}},
                {"$limit": 10}
            ]
            business_stats = await SimpleNotification.aggregate(business_pipeline).to_list()
            
            return {
                "total_notifications": total_notifications,
                "unread_notifications": unread_notifications,
                "read_notifications": total_notifications - unread_notifications,
                "notifications_by_type": {stat["_id"]: stat["count"] for stat in type_stats},
                "top_businesses": {stat["_id"]: stat["count"] for stat in business_stats},
                "max_per_business": self.max_notifications_per_business,
                "retention_days": self.notification_retention_days,
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logging.error(f"Error getting service stats: {e}")
            return {"error": str(e), "timestamp": datetime.utcnow().isoformat()}


# Global simplified notification service instance
simple_notification_service = SimpleNotificationService()
