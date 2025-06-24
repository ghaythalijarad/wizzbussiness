"""
Notification service for real-time order notifications.
"""
import asyncio
import json
import logging
from typing import Dict, List, Set, Optional, Any
from datetime import datetime
from enum import Enum
from fastapi import WebSocket, WebSocketDisconnect
from beanie import PydanticObjectId

from ..models.user import User
from ..models.business import Business
from ..models.order import Order, OrderStatus


class NotificationType(str, Enum):
    """Notification types."""
    NEW_ORDER = "new_order"
    ORDER_UPDATE = "order_update"
    ORDER_CANCELLED = "order_cancelled"
    PAYMENT_RECEIVED = "payment_received"
    SYSTEM_MESSAGE = "system_message"


class NotificationPriority(str, Enum):
    """Notification priority levels."""
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    URGENT = "urgent"


class Notification:
    """Notification data structure."""
    
    def __init__(
        self,
        notification_id: str,
        business_id: str,
        notification_type: NotificationType,
        title: str,
        message: str,
        data: Optional[Dict[str, Any]] = None,
        priority: NotificationPriority = NotificationPriority.NORMAL,
        sound_enabled: bool = True,
        auto_dismiss: bool = False,
        dismiss_after: int = 0  # seconds, 0 = no auto dismiss
    ):
        self.id = notification_id
        self.business_id = business_id
        self.type = notification_type
        self.title = title
        self.message = message
        self.data = data or {}
        self.priority = priority
        self.sound_enabled = sound_enabled
        self.auto_dismiss = auto_dismiss
        self.dismiss_after = dismiss_after
        self.timestamp = datetime.utcnow()
        self.read = False
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert notification to dictionary."""
        return {
            "id": self.id,
            "business_id": self.business_id,
            "type": self.type,
            "title": self.title,
            "message": self.message,
            "data": self.data,
            "priority": self.priority,
            "sound_enabled": self.sound_enabled,
            "auto_dismiss": self.auto_dismiss,
            "dismiss_after": self.dismiss_after,
            "timestamp": self.timestamp.isoformat(),
            "read": self.read
        }


class ConnectionManager:
    """WebSocket connection manager for real-time notifications."""
    
    def __init__(self):
        # Active WebSocket connections: {business_id: {user_id: websocket}}
        self.connections: Dict[str, Dict[str, WebSocket]] = {}
        # User to business mapping: {user_id: business_id}
        self.user_business_map: Dict[str, str] = {}
        # Notification history: {business_id: [notifications]}
        self.notification_history: Dict[str, List[Notification]] = {}
        self.max_history_per_business = 100
    
    async def connect(self, websocket: WebSocket, business_id: str, user_id: str):
        """Accept a new WebSocket connection."""
        await websocket.accept()
        
        if business_id not in self.connections:
            self.connections[business_id] = {}
        
        self.connections[business_id][user_id] = websocket
        self.user_business_map[user_id] = business_id
        
        logging.info(f"User {user_id} connected to business {business_id} notifications")
        
        # Send connection confirmation
        await self.send_to_user(user_id, {
            "type": "connection_established",
            "message": "Connected to notification service",
            "business_id": business_id,
            "timestamp": datetime.utcnow().isoformat()
        })
        
        # Send recent notifications
        await self.send_recent_notifications(user_id, business_id)
    
    def disconnect(self, user_id: str):
        """Remove a WebSocket connection."""
        business_id = self.user_business_map.get(user_id)
        
        if business_id and business_id in self.connections:
            if user_id in self.connections[business_id]:
                del self.connections[business_id][user_id]
                
            # Clean up empty business connections
            if not self.connections[business_id]:
                del self.connections[business_id]
        
        if user_id in self.user_business_map:
            del self.user_business_map[user_id]
        
        logging.info(f"User {user_id} disconnected from notifications")
    
    async def send_to_user(self, user_id: str, data: Dict[str, Any]):
        """Send data to a specific user."""
        business_id = self.user_business_map.get(user_id)
        
        if business_id and business_id in self.connections:
            websocket = self.connections[business_id].get(user_id)
            
            if websocket:
                try:
                    await websocket.send_text(json.dumps(data))
                except Exception as e:
                    logging.error(f"Error sending to user {user_id}: {e}")
                    self.disconnect(user_id)
    
    async def send_to_business(self, business_id: str, data: Dict[str, Any]):
        """Send data to all users connected to a business."""
        if business_id in self.connections:
            disconnected_users = []
            
            for user_id, websocket in self.connections[business_id].items():
                try:
                    await websocket.send_text(json.dumps(data))
                except Exception as e:
                    logging.error(f"Error sending to user {user_id} in business {business_id}: {e}")
                    disconnected_users.append(user_id)
            
            # Clean up disconnected users
            for user_id in disconnected_users:
                self.disconnect(user_id)
    
    async def send_notification(self, notification: Notification):
        """Send notification to business users and store in history."""
        # Add to history
        business_id = notification.business_id
        if business_id not in self.notification_history:
            self.notification_history[business_id] = []
        
        self.notification_history[business_id].append(notification)
        
        # Keep only recent notifications
        if len(self.notification_history[business_id]) > self.max_history_per_business:
            self.notification_history[business_id] = self.notification_history[business_id][-self.max_history_per_business:]
        
        # Send to connected users
        notification_data = {
            "type": "notification",
            "notification": notification.to_dict()
        }
        
        await self.send_to_business(business_id, notification_data)
        
        logging.info(f"Sent {notification.type} notification to business {business_id}: {notification.title}")
    
    async def send_recent_notifications(self, user_id: str, business_id: str, limit: int = 10):
        """Send recent notifications to a newly connected user."""
        recent_notifications = self.notification_history.get(business_id, [])[-limit:]
        
        if recent_notifications:
            await self.send_to_user(user_id, {
                "type": "recent_notifications",
                "notifications": [notif.to_dict() for notif in recent_notifications],
                "count": len(recent_notifications)
            })
    
    def get_business_connections(self, business_id: str) -> int:
        """Get number of active connections for a business."""
        return len(self.connections.get(business_id, {}))
    
    def get_all_connections(self) -> Dict[str, int]:
        """Get connection count for all businesses."""
        return {business_id: len(users) for business_id, users in self.connections.items()}


class NotificationService:
    """Service for managing order notifications."""
    
    def __init__(self):
        self.connection_manager = ConnectionManager()
    
    async def notify_new_order(self, order: Order, business: Business):
        """Send notification for a new order."""
        notification = Notification(
            notification_id=f"order_{order.id}_{datetime.utcnow().timestamp()}",
            business_id=str(business.id),
            notification_type=NotificationType.NEW_ORDER,
            title="🔔 New Order Received!",
            message=f"Order #{order.order_number} from {order.customer_name} - ${order.total_amount:.2f}",
            data={
                "order_id": str(order.id),
                "order_number": order.order_number,
                "customer_name": order.customer_name,
                "total_amount": order.total_amount,
                "items_count": len(order.items),
                "delivery_address": order.delivery_address,
                "phone_number": order.customer_phone,
                "estimated_time": order.estimated_delivery_time
            },
            priority=NotificationPriority.HIGH,
            sound_enabled=True
        )
        
        await self.connection_manager.send_notification(notification)
    
    async def notify_order_update(self, order: Order, business: Business, status: OrderStatus):
        """Send notification for order status update."""
        status_messages = {
            OrderStatus.CONFIRMED: "Order confirmed and being prepared",
            OrderStatus.PREPARING: "Order is being prepared",
            OrderStatus.READY: "Order is ready for pickup/delivery",
            OrderStatus.OUT_FOR_DELIVERY: "Order is out for delivery",
            OrderStatus.DELIVERED: "Order has been delivered",
            OrderStatus.CANCELLED: "Order has been cancelled"
        }
        
        notification = Notification(
            notification_id=f"order_update_{order.id}_{datetime.utcnow().timestamp()}",
            business_id=str(business.id),
            notification_type=NotificationType.ORDER_UPDATE,
            title=f"📦 Order #{order.order_number} Updated",
            message=status_messages.get(status, f"Order status changed to {status}"),
            data={
                "order_id": str(order.id),
                "order_number": order.order_number,
                "old_status": order.status,
                "new_status": status,
                "customer_name": order.customer_name
            },
            priority=NotificationPriority.NORMAL,
            sound_enabled=False
        )
        
        await self.connection_manager.send_notification(notification)
    
    async def notify_order_cancelled(self, order: Order, business: Business, reason: str = ""):
        """Send notification for cancelled order."""
        notification = Notification(
            notification_id=f"order_cancelled_{order.id}_{datetime.utcnow().timestamp()}",
            business_id=str(business.id),
            notification_type=NotificationType.ORDER_CANCELLED,
            title="❌ Order Cancelled",
            message=f"Order #{order.order_number} from {order.customer_name} has been cancelled",
            data={
                "order_id": str(order.id),
                "order_number": order.order_number,
                "customer_name": order.customer_name,
                "reason": reason,
                "refund_amount": order.total_amount
            },
            priority=NotificationPriority.HIGH,
            sound_enabled=True
        )
        
        await self.connection_manager.send_notification(notification)
    
    async def notify_payment_received(self, order: Order, business: Business, amount: float):
        """Send notification for payment received."""
        notification = Notification(
            notification_id=f"payment_{order.id}_{datetime.utcnow().timestamp()}",
            business_id=str(business.id),
            notification_type=NotificationType.PAYMENT_RECEIVED,
            title="💰 Payment Received",
            message=f"Payment of ${amount:.2f} received for Order #{order.order_number}",
            data={
                "order_id": str(order.id),
                "order_number": order.order_number,
                "amount": amount,
                "customer_name": order.customer_name,
                "payment_method": order.payment_method
            },
            priority=NotificationPriority.NORMAL,
            sound_enabled=True
        )
        
        await self.connection_manager.send_notification(notification)
    
    async def send_system_message(self, business_id: str, title: str, message: str, data: Optional[Dict[str, Any]] = None):
        """Send a system message to a business."""
        notification = Notification(
            notification_id=f"system_{business_id}_{datetime.utcnow().timestamp()}",
            business_id=business_id,
            notification_type=NotificationType.SYSTEM_MESSAGE,
            title=title,
            message=message,
            data=data or {},
            priority=NotificationPriority.NORMAL,
            sound_enabled=False
        )
        
        await self.connection_manager.send_notification(notification)
    
    async def get_notification_history(self, business_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Get notification history for a business."""
        notifications = self.connection_manager.notification_history.get(business_id, [])
        recent_notifications = notifications[-limit:] if notifications else []
        return [notif.to_dict() for notif in recent_notifications]
    
    async def mark_notification_read(self, business_id: str, notification_id: str):
        """Mark a notification as read."""
        notifications = self.connection_manager.notification_history.get(business_id, [])
        for notification in notifications:
            if notification.id == notification_id:
                notification.read = True
                break
    
    def get_connection_stats(self) -> Dict[str, Any]:
        """Get connection statistics."""
        return {
            "total_businesses": len(self.connection_manager.connections),
            "total_connections": sum(len(users) for users in self.connection_manager.connections.values()),
            "businesses": self.connection_manager.get_all_connections()
        }


# Global notification service instance
notification_service = NotificationService()
