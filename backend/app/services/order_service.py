"""
Order service containing business logic for updating order status using SQLAlchemy and PostgreSQL.
"""
from typing import Optional
from datetime import datetime
import logging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from ..models.order_sql import Order, OrderStatus
from ..models.business_sql import Business
from .centralized_platform_service import centralized_platform_service
from .customer_notification_service import customer_notification_service

class OrderService:
    @staticmethod
    async def update_order_status(
        business_id: int,
        order_id: int,
        new_status: OrderStatus,
        session: AsyncSession,
        notes: Optional[str] = None,
        estimated_ready_time: Optional[datetime] = None,
        preparation_time_minutes: Optional[int] = None
    ) -> Order:
        """Update status of an order owned by the given business."""
        # find order belonging to business
        result = await session.execute(
            select(Order).where(Order.id == order_id, Order.business_id == business_id)
        )
        order = result.scalar_one_or_none()
        if not order:
            raise ValueError("Order not found")

        # update status and timestamps
        order.status = new_status
        order.updated_at = datetime.utcnow()
        if notes:
            order.notes = notes
        if estimated_ready_time:
            order.estimated_ready_time = estimated_ready_time
        if preparation_time_minutes is not None:
            order.preparation_time_minutes = preparation_time_minutes
        session.add(order)
        await session.commit()
        await session.refresh(order)

        # Send notifications (logic unchanged, but use SQLAlchemy business fetch)
        business = await session.get(Business, business_id)
        if new_status == OrderStatus.CONFIRMED:
            if business:
                await centralized_platform_service.notify_order_confirmed(order, business, notes)
                await customer_notification_service.notify_order_confirmed(order, business, notes)
        elif new_status == OrderStatus.PREPARING:
            if business:
                await customer_notification_service.notify_order_preparing(order, business, estimated_ready_time)
        elif new_status == OrderStatus.READY:
            if business:
                await centralized_platform_service.notify_order_ready(order, business, notes)
                await customer_notification_service.notify_order_ready(order, business)
        elif new_status == OrderStatus.CANCELLED:
            if business:
                await centralized_platform_service.notify_order_cancelled(order, business, notes or "Cancelled by merchant")
                await customer_notification_service.notify_order_cancelled(order, business, notes or "Cancelled by merchant")
        return order
    # ...repeat for other methods, using SQLAlchemy session and models...
