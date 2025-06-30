"""
Order management controller for handling customer orders.
"""
import logging
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel, Field

from ..models.order_sql import Order, OrderStatus, OrderItem, DeliveryAddress, PaymentInfo, DeliveryType
from ..models.business_sql import Business
from ..models.user_sql import User
from ..services.auth_service import current_active_user
from ..services.notification_service import notification_service
from ..services.simple_notification_service import simple_notification_service
from ..services.order_service import OrderService
from ..core.db_manager import get_async_session


class OrderCreateSchema(BaseModel):
    """Schema for creating a new order from customer app."""
    
    # Customer information
    customer_name: str = Field(..., min_length=1, max_length=100)
    customer_phone: str = Field(..., min_length=10, max_length=15)
    customer_email: Optional[str] = None
    customer_id: Optional[str] = None
    
    # Order items
    items: List[OrderItem] = Field(..., min_length=1)
    
    # Delivery information
    delivery_type: DeliveryType = DeliveryType.DELIVERY
    delivery_address: Optional[DeliveryAddress] = None
    delivery_notes: Optional[str] = None
    special_instructions: Optional[str] = None
    
    # Timing
    requested_delivery_time: Optional[datetime] = None
    
    # Payment information
    payment_info: PaymentInfo


class OrderUpdateSchema(BaseModel):
    """Schema for updating order status."""
    status: OrderStatus
    business_notes: Optional[str] = None
    estimated_ready_time: Optional[datetime] = None
    preparation_time_minutes: Optional[int] = None


class OrderResponseSchema(BaseModel):
    """Schema for order response."""
    id: str
    order_number: str
    business_id: str
    customer_name: str
    customer_phone: str
    items_count: int
    total_amount: float
    status: str
    delivery_type: str
    order_date: str
    estimated_delivery_time: Optional[str]
    created_at: str


class OrderController:
    """Controller for order management."""
    
    def __init__(self):
        self.router = APIRouter(prefix="/api/orders", tags=["Orders"])
        self._setup_routes()
    
    def _setup_routes(self):
        """Setup order management routes."""
        
        @self.router.post("/", response_model=OrderResponseSchema)
        async def create_order(
            order_data: OrderCreateSchema,
            current_user: User = Depends(current_active_user),
            session: AsyncSession = Depends(get_async_session)
        ):
            """Create a new order (called by customer app)."""
            try:
                order = await OrderService.create_order(order_data, current_user, session)
                
                # Send notification in background (both systems)
                BackgroundTasks().add_task(
                    notification_service.notify_new_order,
                    order,
                    order.business
                )
                
                # Also send simplified notification (Heroku-friendly)
                BackgroundTasks().add_task(
                    simple_notification_service.send_new_order_notification,
                    order,
                    order.business
                )
                
                logging.info(f"New order created: {order.order_number} for business {order.business_id}")
                
                return OrderResponseSchema.from_orm(order)
                
            except Exception as e:
                logging.error(f"Error creating order: {e}")
                raise HTTPException(status_code=500, detail="Failed to create order")
        
        @self.router.get("/business/{business_id}", response_model=List[OrderResponseSchema])
        async def get_business_orders(
            business_id: str,
            status: Optional[OrderStatus] = Query(None, description="Filter by status"),
            limit: int = Query(50, ge=1, le=100),
            skip: int = Query(0, ge=0),
            current_user: User = Depends(current_active_user),
            session: AsyncSession = Depends(get_async_session)
        ):
            """Get orders for a business."""
            try:
                # Verify business exists and user has access
                business = await Business.get(business_id, session=session)
                if not business:
                    raise HTTPException(status_code=404, detail="Business not found")
                
                # Type guard: business is now guaranteed to exist
                assert business is not None
                if business.owner_id != current_user.id:
                    raise HTTPException(status_code=403, detail="Access denied")
                
                # Build query
                query = Order.find(Order.business_id == business_id)
                
                if status:
                    query = query.filter(Order.status == status)
                
                # Get orders with pagination
                orders = await query.order_by(Order.created_at.desc()).offset(skip).limit(limit).all()
                
                return [OrderResponseSchema.from_orm(order) for order in orders]
                
            except Exception as e:
                logging.error(f"Error getting business orders: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.get("/{order_id}")
        async def get_order(
            order_id: str,
            current_user: User = Depends(current_active_user),
            session: AsyncSession = Depends(get_async_session)
        ):
            """Get a specific order."""
            try:
                order = await Order.get(order_id, session=session)
                if not order:
                    raise HTTPException(status_code=404, detail="Order not found")
                
                # Verify user has access to this order's business
                business = await Business.get(order.business_id, session=session)
                if not business:
                    raise HTTPException(status_code=404, detail="Business not found")
                
                # Type guard: business is now guaranteed to exist
                assert business is not None
                if business.owner_id != current_user.id:
                    raise HTTPException(status_code=403, detail="Access denied")
                
                return order.to_dict()
                
            except Exception as e:
                logging.error(f"Error getting order: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        # New PATCH endpoint for accepting/rejecting orders
        @self.router.patch("/{order_id}/status", response_model=OrderResponseSchema)
        async def change_order_status(
            order_id: str,
            payload: OrderUpdateSchema,
            business_id: str = Query(..., description="Business ID"),
            background_tasks: BackgroundTasks = BackgroundTasks(),
            current_user: User = Depends(current_active_user),
            session: AsyncSession = Depends(get_async_session)
        ):
            """Accept, reject, or update an order's status by the merchant."""
            # Validate business ID
            bid = business_id
            # Delegate update to service (verifies ownership)
            try:
                updated_order = await OrderService.update_order_status(
                    bid,
                    order_id,
                    payload.status,
                    payload.business_notes,
                    payload.estimated_ready_time,
                    payload.preparation_time_minutes,
                    session
                )
            except ValueError as e:
                raise HTTPException(status_code=404, detail=str(e))
            except HTTPException:
                raise
            except Exception as e:
                logging.error(f"Error updating order status: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")

            # Fetch business for notifications
            business = await Business.get(bid, session=session)
            if not business:
                raise HTTPException(status_code=404, detail="Business not found")

            # Send notifications
            if payload.status == OrderStatus.CANCELLED:
                background_tasks.add_task(
                    notification_service.notify_order_cancelled,
                    updated_order,
                    business,
                    payload.business_notes or ""
                )
            else:
                background_tasks.add_task(
                    notification_service.notify_order_update,
                    updated_order,
                    business,
                    payload.status
                )
            return OrderResponseSchema.from_orm(updated_order)
        
        @self.router.get("/stats/{business_id}")
        async def get_order_stats(
            business_id: str,
            current_user: User = Depends(current_active_user),
            session: AsyncSession = Depends(get_async_session)
        ):
            """Get order statistics for a business."""
            try:
                # Verify business exists and user has access
                business = await Business.get(business_id, session=session)
                if not business:
                    raise HTTPException(status_code=404, detail="Business not found")
                
                # Type guard: business is now guaranteed to exist
                assert business is not None
                if business.owner_id != current_user.id:
                    raise HTTPException(status_code=403, detail="Access denied")
                
                # Get statistics
                total_orders = await Order.find(Order.business_id == business_id).count(session=session)
                pending_orders = await Order.find(
                    Order.business_id == business_id,
                    Order.status == OrderStatus.PENDING
                ).count(session=session)
                preparing_orders = await Order.find(
                    Order.business_id == business_id,
                    Order.status == OrderStatus.PREPARING
                ).count(session=session)
                completed_orders = await Order.find(
                    Order.business_id == business_id,
                    In(Order.status, [OrderStatus.DELIVERED, OrderStatus.CANCELLED, OrderStatus.REFUNDED])
                ).count(session=session)
                
                return {
                    "business_id": business_id,
                    "total_orders": total_orders,
                    "pending_orders": pending_orders,
                    "preparing_orders": preparing_orders,
                    "completed_orders": completed_orders,
                    "active_orders": pending_orders + preparing_orders
                }
                
            except Exception as e:
                logging.error(f"Error getting order stats: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")


# Create controller instance
order_controller = OrderController()
