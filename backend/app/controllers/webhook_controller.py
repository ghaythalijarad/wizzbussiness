"""
Webhook controller for receiving updates from the centralized delivery platform.
"""
import logging
from fastapi import APIRouter, HTTPException, Header, Request, Depends
from pydantic import BaseModel
from typing import Dict, Any, Optional
import hmac
import hashlib
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.db_manager import get_async_session
from ..services.centralized_platform_service import centralized_platform_service
from ..services.customer_notification_service import customer_notification_service
from ..services.webhook_service import webhook_service
from ..models.order import OrderStatus


class DriverAssignmentWebhook(BaseModel):
    """Schema for driver assignment webhook from centralized platform."""
    order_id: str
    driver_info: Dict[str, Any]
    estimated_pickup_time: Optional[str] = None
    tracking_url: Optional[str] = None


class OrderStatusWebhook(BaseModel):
    """Schema for order status updates from centralized platform."""
    order_id: str
    status: str
    timestamp: str
    message: Optional[str] = None


class WebhookController:
    """Controller for handling webhooks from centralized platform."""
    
    def __init__(self):
        self.router = APIRouter(prefix="/api/webhooks", tags=["Webhooks"])
        self._setup_routes()
    
    def _verify_webhook_signature(self, payload: bytes, signature: str, secret: str) -> bool:
        """Verify webhook signature for security."""
        try:
            expected_signature = hmac.new(
                secret.encode('utf-8'),
                payload,
                hashlib.sha256
            ).hexdigest()
            return hmac.compare_digest(f"sha256={expected_signature}", signature)
        except Exception:
            return False
    
    def _setup_routes(self):
        """Setup webhook routes."""
        
        @self.router.post("/driver-assignment")
        async def receive_driver_assignment(
            webhook_data: DriverAssignmentWebhook,
            request: Request,
            x_signature: str = Header(None, alias="X-Signature"),
            session: AsyncSession = Depends(get_async_session)
        ):
            """
            Receive driver assignment notification from centralized platform.
            Called when the platform assigns a driver to a confirmed order.
            """
            try:
                # Verify webhook signature (in production)
                # if x_signature:
                #     body = await request.body()
                #     if not self._verify_webhook_signature(body, x_signature, centralized_platform_service.webhook_secret):
                #         raise HTTPException(status_code=401, detail="Invalid signature")
                
                # Process driver assignment
                success = await centralized_platform_service.receive_driver_assignment_webhook(
                    webhook_data.dict(), session
                )
                
                if success:
                    # Get order and business for customer notification
                    from ..models.order import Order
                    from ..models.business import Business
                    
                    order = await Order.get(webhook_data.order_id, session=session)
                    if order:
                        business = await Business.get(order.business_id, session=session)
                        if business:
                            # Notify customer about driver assignment
                            await customer_notification_service.notify_driver_assigned(
                                order, business, webhook_data.driver_info
                            )
                    
                    logging.info(f"Successfully processed driver assignment for order {webhook_data.order_id}")
                    return {"status": "success", "message": "Driver assignment processed"}
                else:
                    raise HTTPException(status_code=400, detail="Failed to process driver assignment")
                    
            except Exception as e:
                logging.error(f"Error processing driver assignment webhook: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.post("/order-status")
        async def receive_order_status_update(
            webhook_data: OrderStatusWebhook,
            request: Request,
            x_signature: str = Header(None, alias="X-Signature"),
            session: AsyncSession = Depends(get_async_session)
        ):
            """
            Receive order status updates from centralized platform.
            Called when order status changes (e.g., picked up, delivered).
            """
            try:
                # Verify webhook signature (in production)
                # if x_signature:
                #     body = await request.body()
                #     if not self._verify_webhook_signature(body, x_signature, centralized_platform_service.webhook_secret):
                #         raise HTTPException(status_code=401, detail="Invalid signature")
                
                # Update order status
                from ..models.order import Order
                from datetime import datetime
                
                order = await Order.get(webhook_data.order_id, session=session)
                if not order:
                    raise HTTPException(status_code=404, detail="Order not found")
                
                # Update order based on status from platform
                if webhook_data.status == "picked_up":
                    order.picked_up_at = datetime.now()
                    order.status = OrderStatus.OUT_FOR_DELIVERY
                elif webhook_data.status == "delivered":
                    order.delivered_at = datetime.now()
                    order.status = OrderStatus.DELIVERED
                    order.completed_at = datetime.now()
                
                await order.save(session=session)
                
                # Send customer notifications for status updates
                from ..models.business import Business
                business = await Business.get(order.business_id, session=session)
                if business:
                    if webhook_data.status == "picked_up":
                        await customer_notification_service.notify_order_picked_up(
                            order, business, order.assigned_driver_info
                        )
                    elif webhook_data.status == "delivered":
                        await customer_notification_service.notify_order_delivered(
                            order, business, webhook_data.message
                        )
                
                logging.info(f"Updated order {webhook_data.order_id} status to {webhook_data.status}")
                return {"status": "success", "message": "Order status updated"}
                
            except Exception as e:
                logging.error(f"Error processing order status webhook: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.get("/health")
        async def webhook_health_check():
            """Health check for webhook endpoints."""
            return {"status": "healthy", "service": "order-receiver-webhooks"}


# Create controller instance
webhook_controller = WebhookController()
