"""
Order service containing business logic for updating order status.
"""
from typing import Optional
from datetime import datetime
import logging
from beanie import PydanticObjectId
from beanie.operators import And

from ..models.order import Order, OrderStatus
from .centralized_platform_service import centralized_platform_service
from .customer_notification_service import customer_notification_service


class OrderService:
    @staticmethod
    async def update_order_status(
        business_id: PydanticObjectId,
        order_id: PydanticObjectId,
        new_status: OrderStatus,
        notes: Optional[str] = None,
        estimated_ready_time: Optional[datetime] = None,
        preparation_time_minutes: Optional[int] = None
    ) -> Order:
        """Update status of an order owned by the given business."""
        # find order belonging to business
        order = await Order.find_one(
            And(
                Order.id == order_id,
                Order.business_id == business_id
            )
        )
        if not order:
            raise ValueError("Order not found")

        # update status and timestamps
        order.update_status(new_status, notes)
        # optional updates
        if estimated_ready_time:
            order.estimated_ready_time = estimated_ready_time
        if preparation_time_minutes is not None:
            order.preparation_time_minutes = preparation_time_minutes

        # Send order status update to centralized platform for driver assignment
        if new_status == OrderStatus.CONFIRMED:
            try:
                # Get business info for the notification
                from ..models.business import Business
                business = await Business.get(business_id)
                if business:
                    # Notify centralized platform
                    await centralized_platform_service.notify_order_confirmed(order, business, notes)
                    
                    # Notify customer about order confirmation
                    await customer_notification_service.notify_order_confirmed(order, business, notes)
                    
                else:
                    logging.warning(f"Business {business_id} not found for order {order_id}")
                
            except Exception as e:
                logging.error(f"Error notifying centralized platform for order {order_id}: {e}")
        
        elif new_status == OrderStatus.PREPARING:
            try:
                from ..models.business import Business
                business = await Business.get(business_id)
                if business:
                    # Notify customer that order is being prepared
                    await customer_notification_service.notify_order_preparing(
                        order, business, estimated_ready_time
                    )
                    
            except Exception as e:
                logging.error(f"Error notifying customer for preparing order {order_id}: {e}")
        
        elif new_status == OrderStatus.READY:
            try:
                from ..models.business import Business
                business = await Business.get(business_id)
                if business:
                    # Notify centralized platform
                    await centralized_platform_service.notify_order_ready(order, business, notes)
                    # Notify customer that order is ready
                    await customer_notification_service.notify_order_ready(order, business)
            
            except Exception as e:
                logging.error(f"Error notifying centralized platform for ready order {order_id}: {e}")
        
        elif new_status == OrderStatus.CANCELLED:
            try:
                from ..models.business import Business
                business = await Business.get(business_id)
                if business:
                    # Notify centralized platform
                    await centralized_platform_service.notify_order_cancelled(order, business, notes or "Cancelled by merchant")
                    # Notify customer about cancellation
                    await customer_notification_service.notify_order_cancelled(
                        order, business, notes or "Cancelled by merchant"
                    )
                
            except Exception as e:
                logging.error(f"Error notifying centralized platform for cancelled order {order_id}: {e}")

        # save and return
        await order.save()
        logging.info(f"Order {order_id} status updated to {new_status}")
        return order
