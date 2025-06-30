"""
WebSocket controller for real-time notifications.
"""
import json
import logging
from typing import Optional
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from ..services.notification_service import notification_service
from ..services.auth_service import current_active_user
from ..models.user_sql import User
from ..models.business_sql import Business
from ..core.db_manager import get_async_session


class NotificationWebSocketController:
    """WebSocket controller for real-time notifications."""
    
    def __init__(self):
        self.router = APIRouter()
        self._setup_routes()
    
    def _setup_routes(self):
        """Setup WebSocket and HTTP routes."""
        
        @self.router.websocket("/ws/notifications/{business_id}")
        async def websocket_endpoint(
            websocket: WebSocket,
            business_id: str,
            token: Optional[str] = Query(None),
            user_id: Optional[str] = Query(None)
        ):
            """WebSocket endpoint for real-time notifications."""
            try:
                # Validate business ID
                try:
                    business_obj_id = PydanticObjectId(business_id)
                except Exception:
                    await websocket.close(code=4000, reason="Invalid business ID")
                    return
                
                # Verify business exists
                business = await Business.get(business_obj_id)
                if not business:
                    await websocket.close(code=4004, reason="Business not found")
                    return
                
                # For now, we'll use a simple user_id parameter
                # In production, you'd validate the token and extract user info
                if not user_id:
                    await websocket.close(code=4001, reason="User ID required")
                    return
                
                # TODO: Add proper token validation here
                # user = await validate_websocket_token(token)
                # if not user:
                #     await websocket.close(code=4003, reason="Invalid token")
                #     return
                
                # Connect to notification service
                await notification_service.connection_manager.connect(
                    websocket, business_id, user_id
                )
                
                try:
                    # Keep connection alive and handle incoming messages
                    while True:
                        # Wait for messages from client
                        data = await websocket.receive_text()
                        
                        try:
                            message = json.loads(data)
                            await self._handle_client_message(message, business_id, user_id)
                        except json.JSONDecodeError:
                            logging.error(f"Invalid JSON from client {user_id}: {data}")
                        except Exception as e:
                            logging.error(f"Error handling client message: {e}")
                
                except WebSocketDisconnect:
                    logging.info(f"Client {user_id} disconnected from business {business_id}")
                
            except Exception as e:
                logging.error(f"WebSocket error: {e}")
            
            finally:
                # Clean up connection
                if user_id:
                    notification_service.connection_manager.disconnect(user_id)
        
        @self.router.get("/notifications/history/{business_id}")
        async def get_notification_history(
            business_id: str,
            limit: int = Query(50, ge=1, le=100),
            current_user: User = Depends(current_active_user),
            session: AsyncSession = Depends(get_async_session)
        ):
            """Get notification history for a business."""
            try:
                business_obj_id = PydanticObjectId(business_id)
                
                # Verify business exists and user has access
                business = await Business.get(business_obj_id)
                if not business:
                    raise HTTPException(status_code=404, detail="Business not found")
                
                # Check if user owns the business
                if business.owner_id != current_user.id:
                    raise HTTPException(status_code=403, detail="Access denied")
                
                history = await notification_service.get_notification_history(business_id, limit)
                return {
                    "notifications": history,
                    "count": len(history),
                    "business_id": business_id
                }
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid business ID")
            except Exception as e:
                logging.error(f"Error getting notification history: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.post("/notifications/mark-read/{business_id}/{notification_id}")
        async def mark_notification_read(
            business_id: str,
            notification_id: str,
            current_user: User = Depends(current_active_user),
            session: AsyncSession = Depends(get_async_session)
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
                
                await notification_service.mark_notification_read(business_id, notification_id)
                return {"message": "Notification marked as read"}
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid business ID")
            except Exception as e:
                logging.error(f"Error marking notification as read: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.get("/notifications/stats")
        async def get_notification_stats(
            current_user: User = Depends(current_active_user)
        ):
            """Get notification service statistics (admin only)."""
            if not current_user.is_superuser:
                raise HTTPException(status_code=403, detail="Admin access required")
            
            stats = notification_service.get_connection_stats()
            return stats
        
        @self.router.post("/notifications/test/{business_id}")
        async def send_test_notification(
            business_id: str,
            current_user: User = Depends(current_active_user),
            session: AsyncSession = Depends(get_async_session)
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
                
                await notification_service.send_system_message(
                    business_id=business_id,
                    title="🧪 Test Notification",
                    message="This is a test notification to verify the system is working correctly.",
                    data={
                        "test": True,
                        "sender": current_user.email,
                        "timestamp": "now"
                    }
                )
                
                return {"message": "Test notification sent successfully"}
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid business ID")
            except Exception as e:
                logging.error(f"Error sending test notification: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
    
    async def _handle_client_message(self, message: dict, business_id: str, user_id: str):
        """Handle incoming messages from WebSocket clients."""
        message_type = message.get("type")
        
        if message_type == "ping":
            # Respond to ping with pong
            await notification_service.connection_manager.send_to_user(user_id, {
                "type": "pong",
                "timestamp": message.get("timestamp")
            })
        
        elif message_type == "mark_read":
            # Mark notification as read
            notification_id = message.get("notification_id")
            if notification_id:
                await notification_service.mark_notification_read(business_id, notification_id)
        
        elif message_type == "request_history":
            # Send recent notifications
            limit = message.get("limit", 10)
            await notification_service.connection_manager.send_recent_notifications(
                user_id, business_id, limit
            )
        
        else:
            logging.warning(f"Unknown message type from client {user_id}: {message_type}")


# Create controller instance
notification_ws_controller = NotificationWebSocketController()
