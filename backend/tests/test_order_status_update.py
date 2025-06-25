"""
Unit tests for order status update functionality.
"""
import pytest
from unittest.mock import AsyncMock, patch
from datetime import datetime
from beanie import PydanticObjectId

from app.services.order_service import OrderService
from app.models.order import Order, OrderStatus


class TestOrderStatusUpdate:
    """Test cases for order status update service."""

    @pytest.mark.asyncio
    async def test_update_order_status_success(self):
        """Test successful order status update."""
        # Mock order
        mock_order = Order(
            order_number="TEST001",
            business_id=PydanticObjectId(),
            customer_name="Test Customer",
            customer_phone="1234567890",
            items=[],
            status=OrderStatus.PENDING
        )
        
        # Mock the database operations
        with patch('app.models.order.Order.find_one', new_callable=AsyncMock) as mock_find, \
             patch.object(mock_order, 'save', new_callable=AsyncMock) as mock_save, \
             patch.object(mock_order, 'update_status') as mock_update_status:
            
            mock_find.return_value = mock_order
            mock_save.return_value = None
            
            # Test the update
            result = await OrderService.update_order_status(
                business_id=PydanticObjectId(),
                order_id=PydanticObjectId(),
                new_status=OrderStatus.CONFIRMED,
                notes="Order confirmed by merchant"
            )
            
            # Assertions
            assert result == mock_order
            mock_update_status.assert_called_once_with(OrderStatus.CONFIRMED, "Order confirmed by merchant")
            mock_save.assert_called_once()

    @pytest.mark.asyncio
    async def test_update_order_status_not_found(self):
        """Test order status update when order is not found."""
        with patch('app.models.order.Order.find_one', new_callable=AsyncMock) as mock_find:
            mock_find.return_value = None
            
            # Test the update should raise ValueError
            with pytest.raises(ValueError, match="Order not found"):
                await OrderService.update_order_status(
                    business_id=PydanticObjectId(),
                    order_id=PydanticObjectId(),
                    new_status=OrderStatus.CONFIRMED
                )

    @pytest.mark.asyncio
    async def test_update_order_status_with_optional_fields(self):
        """Test order status update with optional fields."""
        # Mock order
        mock_order = Order(
            order_number="TEST002",
            business_id=PydanticObjectId(),
            customer_name="Test Customer 2",
            customer_phone="1234567890",
            items=[],
            status=OrderStatus.PENDING
        )
        
        estimated_time = datetime.now()
        prep_time = 30
        
        with patch('app.models.order.Order.find_one', new_callable=AsyncMock) as mock_find, \
             patch.object(mock_order, 'save', new_callable=AsyncMock) as mock_save, \
             patch.object(mock_order, 'update_status') as mock_update_status:
            
            mock_find.return_value = mock_order
            mock_save.return_value = None
            
            # Test the update with optional fields
            result = await OrderService.update_order_status(
                business_id=PydanticObjectId(),
                order_id=PydanticObjectId(),
                new_status=OrderStatus.PREPARING,
                notes="Starting preparation",
                estimated_ready_time=estimated_time,
                preparation_time_minutes=prep_time
            )
            
            # Assertions
            assert result == mock_order
            assert mock_order.estimated_ready_time == estimated_time
            assert mock_order.preparation_time_minutes == prep_time
            mock_update_status.assert_called_once_with(OrderStatus.PREPARING, "Starting preparation")
            mock_save.assert_called_once()


if __name__ == "__main__":
    pytest.main([__file__])
