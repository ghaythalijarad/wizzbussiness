"""
Order management controller for handling customer orders.
"""
import logging
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from beanie import PydanticObjectId
from pydantic import BaseModel, Field

from ..models.order import Order, OrderStatus, OrderItem, DeliveryAddress, PaymentInfo, DeliveryType
from ..models.business import Business
from ..models.user import User
from ..services.auth_service import current_active_user
from ..services.notification_service import notification_service


class OrderCreateSchema(BaseModel):
    """Schema for creating a new order from customer app."""
    
    # Customer information
    customer_name: str = Field(..., min_length=1, max_length=100)
    customer_phone: str = Field(..., min_length=10, max_length=15)
    customer_email: Optional[str] = None
    customer_id: Optional[str] = None
    
    # Order items
    items: List[OrderItem] = Field(..., min_items=1)
    
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
            business_id: str = Query(..., description="Business ID"),
            order_data: OrderCreateSchema = ...,
            background_tasks: BackgroundTasks = BackgroundTasks()
        ):
            """Create a new order (called by customer app)."""
            try:
                business_obj_id = PydanticObjectId(business_id)
                
                # Verify business exists and is active
                business = await Business.get(business_obj_id)
                if not business:
                    raise HTTPException(status_code=404, detail="Business not found")
                
                if not business.is_online:
                    raise HTTPException(status_code=400, detail="Business is currently offline")
                
                # Generate order number
                order_count = await Order.find(Order.business_id == business_obj_id).count()
                order_number = f"{business.name[:3].upper()}{order_count + 1:04d}"
                
                # Create order
                order = Order(
                    order_number=order_number,
                    business_id=business_obj_id,
                    customer_name=order_data.customer_name,
                    customer_phone=order_data.customer_phone,
                    customer_email=order_data.customer_email,
                    customer_id=order_data.customer_id,
                    items=order_data.items,
                    delivery_type=order_data.delivery_type,
                    delivery_address=order_data.delivery_address,
                    delivery_notes=order_data.delivery_notes,
                    special_instructions=order_data.special_instructions,
                    requested_delivery_time=order_data.requested_delivery_time,
                    payment_info=order_data.payment_info
                )
                
                # Calculate estimated delivery time
                order.calculate_estimated_time()
                
                # Save order
                await order.insert()
                
                # Send notification in background
                background_tasks.add_task(
                    notification_service.notify_new_order,
                    order,
                    business
                )
                
                logging.info(f"New order created: {order.order_number} for business {business_id}")
                
                return OrderResponseSchema(**order.to_dict())
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid business ID")
            except Exception as e:
                logging.error(f"Error creating order: {e}")
                raise HTTPException(status_code=500, detail="Failed to create order")
        
        @self.router.get("/business/{business_id}", response_model=List[OrderResponseSchema])
        async def get_business_orders(
            business_id: str,
            status: Optional[OrderStatus] = Query(None, description="Filter by status"),
            limit: int = Query(50, ge=1, le=100),
            skip: int = Query(0, ge=0),
            current_user: User = Depends(current_active_user)
        ):
            """Get orders for a business."""
            try:
                business_obj_id = PydanticObjectId(business_id)
                
                # Verify business exists and user has access
                business = await Business.get(business_obj_id)
                if not business:
                    raise HTTPException(status_code=404, detail="Business not found")
                
                if business.owner_id != current_user.id:
                    raise HTTPException(status_code=403, detail="Access denied")
                
                # Build query
                query = Order.find(Order.business_id == business_obj_id)
                
                if status:
                    query = query.find(Order.status == status)
                
                # Get orders with pagination
                orders = await query.sort(-Order.created_at).skip(skip).limit(limit).to_list()
                
                return [OrderResponseSchema(**order.to_dict()) for order in orders]
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid business ID")
            except Exception as e:
                logging.error(f"Error getting business orders: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.get("/{order_id}")
        async def get_order(
            order_id: str,
            current_user: User = Depends(current_active_user)
        ):
            """Get a specific order."""
            try:
                order_obj_id = PydanticObjectId(order_id)
                
                order = await Order.get(order_obj_id)
                if not order:
                    raise HTTPException(status_code=404, detail="Order not found")
                
                # Verify user has access to this order's business
                business = await Business.get(order.business_id)
                if business.owner_id != current_user.id:
                    raise HTTPException(status_code=403, detail="Access denied")
                
                return order.to_dict()
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid order ID")
            except Exception as e:
                logging.error(f"Error getting order: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.put("/{order_id}/status", response_model=OrderResponseSchema)
        async def update_order_status(
            order_id: str,
            update_data: OrderUpdateSchema,
            background_tasks: BackgroundTasks = BackgroundTasks(),
            current_user: User = Depends(current_active_user)
        ):
            """Update order status."""
            try:
                order_obj_id = PydanticObjectId(order_id)
                
                order = await Order.get(order_obj_id)
                if not order:
                    raise HTTPException(status_code=404, detail="Order not found")
                
                # Verify user has access to this order's business
                business = await Business.get(order.business_id)
                if business.owner_id != current_user.id:
                    raise HTTPException(status_code=403, detail="Access denied")
                
                # Update order
                old_status = order.status
                order.update_status(update_data.status, update_data.business_notes)
                
                if update_data.estimated_ready_time:
                    order.estimated_ready_time = update_data.estimated_ready_time
                
                if update_data.preparation_time_minutes:
                    order.preparation_time_minutes = update_data.preparation_time_minutes
                
                await order.save()
                
                # Send notification for status change
                if old_status != update_data.status:
                    if update_data.status == OrderStatus.CANCELLED:
                        background_tasks.add_task(
                            notification_service.notify_order_cancelled,
                            order,
                            business,
                            update_data.business_notes or ""
                        )
                    else:
                        background_tasks.add_task(
                            notification_service.notify_order_update,
                            order,
                            business,
                            update_data.status
                        )
                
                logging.info(f"Order {order.order_number} status updated to {update_data.status}")
                
                return OrderResponseSchema(**order.to_dict())
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid order ID")
            except Exception as e:
                logging.error(f"Error updating order status: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")
        
        @self.router.get("/stats/{business_id}")
        async def get_order_stats(
            business_id: str,
            current_user: User = Depends(current_active_user)
        ):
            """Get order statistics for a business."""
            try:
                business_obj_id = PydanticObjectId(business_id)
                
                # Verify business exists and user has access
                business = await Business.get(business_obj_id)
                if not business:
                    raise HTTPException(status_code=404, detail="Business not found")
                
                if business.owner_id != current_user.id:
                    raise HTTPException(status_code=403, detail="Access denied")
                
                # Get statistics
                total_orders = await Order.find(Order.business_id == business_obj_id).count()
                pending_orders = await Order.find(
                    Order.business_id == business_obj_id,
                    Order.status == OrderStatus.PENDING
                ).count()
                preparing_orders = await Order.find(
                    Order.business_id == business_obj_id,
                    Order.status == OrderStatus.PREPARING
                ).count()
                completed_orders = await Order.find(
                    Order.business_id == business_obj_id,
                    Order.status.in_([OrderStatus.DELIVERED, OrderStatus.COMPLETED])
                ).count()
                
                return {
                    "business_id": business_id,
                    "total_orders": total_orders,
                    "pending_orders": pending_orders,
                    "preparing_orders": preparing_orders,
                    "completed_orders": completed_orders,
                    "active_orders": pending_orders + preparing_orders
                }
                
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid business ID")
            except Exception as e:
                logging.error(f"Error getting order stats: {e}")
                raise HTTPException(status_code=500, detail="Internal server error")


# Create controller instance
order_controller = OrderController()
