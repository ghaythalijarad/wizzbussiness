"""
Customer tracking controller for providing real-time order tracking to customer apps.
"""
import logging
from typing import Optional
from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ..models.order_sql import Order
from ..models.business_sql import Business
from ..services.customer_notification_service import customer_notification_service
from ..core.db_manager import get_async_session


class CustomerTrackingController:
    """Controller for customer order tracking functionality."""
    
    def __init__(self):
        self.router = APIRouter(prefix="/api/customer", tags=["Customer Tracking"])
        self._setup_routes()
    
    def _setup_routes(self):
        """Setup customer tracking routes."""
        
        @self.router.get("/orders/{order_id}/tracking")
        async def get_order_tracking(
            order_id: str,
            customer_phone: str = Query(..., description="Customer phone for verification"),
            session: AsyncSession = Depends(get_async_session)
        ):
            """
            Get real-time tracking information for a customer's order.
            Requires customer phone for security verification.
            """
            try:
                order_obj_id = PydanticObjectId(order_id)
                
                # Get order
                order = await Order.get(order_obj_id, session=session)
                if not order:
                    raise HTTPException(status_code=404, detail="Order not found")
                
                # Verify customer phone for security
                if order.customer_phone != customer_phone:
                    raise HTTPException(status_code=403, detail="Access denied")
                
                # Get business info
                business = await Business.get(order.business_id, session=session)
                if not business:
                    raise HTTPException(status_code=404, detail="Business not found")
                
                # Build tracking response
                tracking_info = {
                    "order_id": str(order.id),
                    "order_number": order.order_number,
                    "status": order.status,
                    "customer_info": {
                        "name": order.customer_name,
                        "phone": order.customer_phone
                    },
                    "business_info": {
                        "name": business.name,
                        "type": business.business_type,
                        "phone": business.phone,
                        "address": business.address.dict() if business.address else None
                    },
                    "order_details": {
                        "total_amount": order.total_amount,
                        "delivery_type": order.delivery_type,
                        "items_count": len(order.items),
                        "special_instructions": order.special_instructions
                    },
                    "timing": {
                        "order_placed_at": order.created_at.isoformat(),
                        "confirmed_at": order.confirmed_at.isoformat() if order.confirmed_at else None,
                        "estimated_ready_time": order.estimated_ready_time.isoformat() if order.estimated_ready_time else None,
                        "estimated_delivery_time": order.estimated_delivery_time.isoformat() if order.estimated_delivery_time else None,
                        "picked_up_at": order.picked_up_at.isoformat() if order.picked_up_at else None,
                        "delivered_at": order.delivered_at.isoformat() if order.delivered_at else None
                    },
                    "driver_info": order.assigned_driver_info if order.assigned_driver_info else None,
                    "delivery_address": order.delivery_address.dict() if order.delivery_address else None,
                    "business_notes": order.business_notes,
                    "status_history": []
                }
                
                # Add status timeline
                timeline = []
                if order.created_at:
                    timeline.append({
                        "status": "Order Placed",
                        "timestamp": order.created_at.isoformat(),
                        "description": f"Order placed at {business.name}"
                    })
                
                if order.confirmed_at:
                    timeline.append({
                        "status": "Order Confirmed",
                        "timestamp": order.confirmed_at.isoformat(),
                        "description": f"{business.name} confirmed your order"
                    })
                
                if order.status == "preparing":
                    timeline.append({
                        "status": "Preparing",
                        "timestamp": order.confirmed_at.isoformat() if order.confirmed_at else order.updated_at.isoformat(),
                        "description": "Your order is being prepared"
                    })
                
                if order.status in ["ready", "out_for_delivery", "delivered"]:
                    timeline.append({
                        "status": "Ready",
                        "timestamp": order.estimated_ready_time.isoformat() if order.estimated_ready_time else order.updated_at.isoformat(),
                        "description": "Your order is ready"
                    })
                
                if order.assigned_driver_info and order.driver_assigned_at:
                    timeline.append({
                        "status": "Driver Assigned",
                        "timestamp": order.driver_assigned_at.isoformat(),
                        "description": f"Driver {order.assigned_driver_info.get('driver_name', 'assigned')} will deliver your order"
                    })
                
                if order.picked_up_at:
                    timeline.append({
                        "status": "Picked Up",
                        "timestamp": order.picked_up_at.isoformat(),
                        "description": "Driver picked up your order and is on the way"
                    })
                
                if order.delivered_at:
                    timeline.append({
                        "status": "Delivered",
                        "timestamp": order.delivered_at.isoformat(),
                        "description": "Your order has been delivered!"
                    })
                
                tracking_info["status_history"] = timeline
                
                return tracking_info
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid order ID")
            except Exception as e:
                logging.error(f"Error getting order tracking: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.get("/orders/{order_id}/live-tracking")
        async def get_live_tracking(
            order_id: str,
            customer_phone: str = Query(..., description="Customer phone for verification"),
            session: AsyncSession = Depends(get_async_session)
        ):
            """
            Get live tracking information from centralized platform.
            Includes real-time driver location if available.
            """
            try:
                # Verify order and customer
                order_obj_id = PydanticObjectId(order_id)
                order = await Order.get(order_obj_id, session=session)
                
                if not order or order.customer_phone != customer_phone:
                    raise HTTPException(status_code=404, detail="Order not found")
                
                # Get live tracking from centralized platform
                live_tracking = await customer_notification_service.get_customer_tracking_info(order_id)
                
                if not live_tracking:
                    # Fallback to basic tracking info
                    return {
                        "order_id": order_id,
                        "status": order.status,
                        "live_tracking_available": False,
                        "message": "Live tracking not available"
                    }
                
                return {
                    "order_id": order_id,
                    "live_tracking_available": True,
                    "tracking_data": live_tracking
                }
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid order ID")
            except Exception as e:
                logging.error(f"Error getting live tracking: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.post("/orders/{order_id}/request-update")
        async def request_order_update(
            order_id: str,
            customer_phone: str = Query(..., description="Customer phone for verification"),
            session: AsyncSession = Depends(get_async_session)
        ):
            """
            Allow customer to request an update on their order status.
            """
            try:
                order_obj_id = PydanticObjectId(order_id)
                order = await Order.get(order_obj_id, session=session)
                
                if not order or order.customer_phone != customer_phone:
                    raise HTTPException(status_code=404, detail="Order not found")
                
                # Log the update request
                logging.info(f"Customer requested update for order {order.order_number}")
                
                # In a real implementation, this could trigger notifications to the business
                # or request fresh status from the centralized platform
                
                return {
                    "message": "Update request received",
                    "order_id": order_id,
                    "current_status": order.status,
                    "estimated_time": order.estimated_delivery_time.isoformat() if order.estimated_delivery_time else None
                }
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid order ID")
            except Exception as e:
                logging.error(f"Error processing update request: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")


# Create controller instance
customer_tracking_controller = CustomerTrackingController()
