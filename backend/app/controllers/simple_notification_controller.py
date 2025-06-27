"""
Simplified Notification Controller for Heroku Deployment (Deprecated)
=====================================================================

HTTP-based notification endpoints that were used for Heroku deployment.
This controller is deprecated in favor of Redis/WebSocket notifications.
"""
import logging
from typing import Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query
from beanie import PydanticObjectId

from ..services.simple_notification_service import simple_notification_service
from ..services.auth_service import current_active_user
from ..models.user import User
from ..models.business import Business


class SimpleNotificationController:
    """HTTP-based notification controller for Heroku deployment (deprecated)."""
    
    def __init__(self):
        self.router = APIRouter()
        self._setup_routes()
    
    def _setup_routes(self):
        """Setup HTTP routes for notifications."""
        
        @self.router.get("/simple/notifications/{business_id}")
        async def get_notifications(
            business_id: str,
            limit: int = Query(50, ge=1, le=100),
            unread_only: bool = Query(False),
            current_user: User = Depends(current_active_user)
        ):
            """Get notifications for a business (polling endpoint)."""
            try:
                business_obj_id = PydanticObjectId(business_id)
                
                # Verify business exists and user has access
                business = await Business.get(business_obj_id)
                if not business:
                    raise HTTPException(status_code=404, detail="Business not found")
                
                # Check if user owns the business
                if business.owner_id != current_user.id:
                    raise HTTPException(status_code=403, detail="Access denied")
                
                notifications = await simple_notification_service.get_notifications(
                    business_id, limit, unread_only
                )
                
                unread_count = await simple_notification_service.get_unread_count(business_id)
                
                return {
                    "notifications": notifications,
                    "total_count": len(notifications),
                    "unread_count": unread_count,
                    "business_id": business_id,
                    "limit": limit,
                    "unread_only": unread_only
                }
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid business ID")
            except Exception as e:
                logging.error(f"Error getting notifications: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.get("/simple/notifications/{business_id}/unread-count")
        async def get_unread_count(
            business_id: str,
            current_user: User = Depends(current_active_user)
        ):
            """Get unread notification count for a business."""
            try:
                business_obj_id = PydanticObjectId(business_id)
                
                # Verify business exists and user has access
                business = await Business.get(business_obj_id)
                if not business:
                    raise HTTPException(status_code=404, detail="Business not found")
                
                if business.owner_id != current_user.id:
                    raise HTTPException(status_code=403, detail="Access denied")
                
                unread_count = await simple_notification_service.get_unread_count(business_id)
                
                return {
                    "business_id": business_id,
                    "unread_count": unread_count
                }
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid business ID")
            except Exception as e:
                logging.error(f"Error getting unread count: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.post("/simple/notifications/{business_id}/{notification_id}/mark-read")
        async def mark_notification_read(
            business_id: str,
            notification_id: str,
            current_user: User = Depends(current_active_user)
        ):
            """Mark a notification as read."""
            try:
                business_obj_id = PydanticObjectId(business_id)
                
                # Verify business exists and user has access
                business = await Business.get(business_obj_id)
                if not business:
                    raise HTTPException(status_code=404, detail="Business not found")
                
                if business.owner_id != current_user.id:
                    raise HTTPException(status_code=403, detail="Access denied")
                
                success = await simple_notification_service.mark_notification_read(
                    business_id, notification_id
                )
                
                if success:
                    return {"message": "Notification marked as read"}
                else:
                    raise HTTPException(status_code=404, detail="Notification not found")
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid business or notification ID")
            except Exception as e:
                logging.error(f"Error marking notification as read: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.post("/simple/notifications/{business_id}/mark-all-read")
        async def mark_all_notifications_read(
            business_id: str,
            current_user: User = Depends(current_active_user)
        ):
            """Mark all notifications as read for a business."""
            try:
                business_obj_id = PydanticObjectId(business_id)
                
                # Verify business exists and user has access
                business = await Business.get(business_obj_id)
                if not business:
                    raise HTTPException(status_code=404, detail="Business not found")
                
                if business.owner_id != current_user.id:
                    raise HTTPException(status_code=403, detail="Access denied")
                
                success = await simple_notification_service.mark_all_read(business_id)
                
                if success:
                    return {"message": "All notifications marked as read"}
                else:
                    raise HTTPException(status_code=500, detail="Failed to mark notifications as read")
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid business ID")
            except Exception as e:
                logging.error(f"Error marking all notifications as read: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.delete("/simple/notifications/{business_id}/{notification_id}")
        async def delete_notification(
            business_id: str,
            notification_id: str,
            current_user: User = Depends(current_active_user)
        ):
            """Delete a specific notification."""
            try:
                business_obj_id = PydanticObjectId(business_id)
                
                # Verify business exists and user has access
                business = await Business.get(business_obj_id)
                if not business:
                    raise HTTPException(status_code=404, detail="Business not found")
                
                if business.owner_id != current_user.id:
                    raise HTTPException(status_code=403, detail="Access denied")
                
                success = await simple_notification_service.delete_notification(
                    business_id, notification_id
                )
                
                if success:
                    return {"message": "Notification deleted"}
                else:
                    raise HTTPException(status_code=404, detail="Notification not found")
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid business or notification ID")
            except Exception as e:
                logging.error(f"Error deleting notification: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.post("/simple/notifications/{business_id}/test")
        async def send_test_notification(
            business_id: str,
            current_user: User = Depends(current_active_user)
        ):
            """Send a test notification (for development/testing)."""
            try:
                business_obj_id = PydanticObjectId(business_id)
                
                # Verify business exists and user has access
                business = await Business.get(business_obj_id)
                if not business:
                    raise HTTPException(status_code=404, detail="Business not found")
                
                if business.owner_id != current_user.id:
                    raise HTTPException(status_code=403, detail="Access denied")
                
                success = await simple_notification_service.send_system_message(
                    business_id=business_id,
                    title="🧪 Test Notification",
                    message="This is a test notification from the simplified notification system.",
                    data={
                        "test": True,
                        "sender": current_user.email,
                        "system": "simplified"
                    }
                )
                
                if success:
                    return {"message": "Test notification sent successfully"}
                else:
                    raise HTTPException(status_code=500, detail="Failed to send test notification")
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid business ID")
            except Exception as e:
                logging.error(f"Error sending test notification: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.get("/simple/notifications/stats")
        async def get_notification_stats(
            current_user: User = Depends(current_active_user)
        ):
            """Get notification service statistics (admin only)."""
            if not current_user.is_superuser:
                raise HTTPException(status_code=403, detail="Admin access required")
            
            stats = await simple_notification_service.get_service_stats()
            return stats
        
        @self.router.post("/simple/notifications/cleanup")
        async def cleanup_expired_notifications(
            current_user: User = Depends(current_active_user)
        ):
            """Clean up expired notifications (admin only)."""
            if not current_user.is_superuser:
                raise HTTPException(status_code=403, detail="Admin access required")
            
            try:
                cleaned_count = await simple_notification_service.cleanup_expired_notifications()
                return {
                    "message": f"Cleaned up {cleaned_count} expired notifications",
                    "cleaned_count": cleaned_count
                }
                
            except Exception as e:
                logging.error(f"Error cleaning up notifications: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")


# Create controller instance
simple_notification_controller = SimpleNotificationController()
