# Customer Notification Service Documentation

## Overview

The Customer Notification Service is a comprehensive service that handles real-time notifications to customers about their order status updates. It integrates with a centralized platform to provide seamless communication between the order receiver app and customer applications.

## Table of Contents

1. [Architecture](#architecture)
2. [Components](#components)
3. [Notification Types](#notification-types)
4. [API Reference](#api-reference)
5. [Configuration](#configuration)
6. [Usage Examples](#usage-examples)
7. [Error Handling](#error-handling)
8. [Best Practices](#best-practices)

## Architecture

The service follows a centralized notification architecture where:

1. **Order Receiver App** → Sends notifications via HTTP API
2. **Centralized Platform** → Routes notifications to appropriate customer apps
3. **Customer Apps** → Receive and display notifications to end users

```
┌─────────────────┐    HTTP API    ┌──────────────────┐    Push/WebSocket    ┌─────────────────┐
│ Order Receiver  │─────────────→  │ Centralized      │─────────────────────→│ Customer Apps   │
│ App (Merchant)  │                │ Platform         │                      │ (iOS/Android)   │
└─────────────────┘                └──────────────────┘                      └─────────────────┘
```

## Components

### NotificationType Enum

Defines all supported notification types for the order lifecycle:

```python
class NotificationType(str, Enum):
    ORDER_CONFIRMED = "order_confirmed"           # Order accepted by merchant
    ORDER_PREPARING = "order_preparing"           # Preparation started
    ORDER_READY = "order_ready"                  # Ready for pickup/delivery
    DRIVER_ASSIGNED = "driver_assigned"          # Driver assigned to order
    ORDER_PICKED_UP = "order_picked_up"         # Driver picked up order
    ORDER_OUT_FOR_DELIVERY = "order_out_for_delivery"  # En route to customer
    ORDER_DELIVERED = "order_delivered"          # Successfully delivered
    ORDER_CANCELLED = "order_cancelled"          # Order cancelled
    ESTIMATED_TIME_UPDATE = "estimated_time_update"    # Time estimate changed
```

### CustomerNotificationService Class

The main service class that handles all notification operations.

#### Initialization

```python
def __init__(self):
    self.platform_base_url = getattr(config, 'centralized_platform_url', 'https://api.delivery-platform.com')
    self.api_key = getattr(config, 'centralized_platform_api_key', 'your-api-key')
    self.service_name = "order-receiver-app"
```

## Notification Types

### 1. Order Confirmed
**Trigger**: When merchant accepts/confirms an order
**Purpose**: Inform customer that their order is confirmed and provide preparation time

**Data Included**:
- Order confirmation details
- Estimated ready time
- Preparation time in minutes
- Business notes (optional)

### 2. Order Preparing
**Trigger**: When merchant starts preparing the order
**Purpose**: Keep customer informed about preparation progress

**Data Included**:
- Current preparation status
- Updated estimated ready time

### 3. Order Ready
**Trigger**: When order is ready for pickup or delivery assignment
**Purpose**: Notify customer that food is prepared

**Behavior**:
- **Pickup orders**: Direct notification to come pick up
- **Delivery orders**: Notification that driver assignment is pending

### 4. Driver Assigned
**Trigger**: When a driver is assigned to deliver the order
**Purpose**: Provide driver information and enable tracking

**Data Included**:
- Driver name and contact info
- Vehicle type
- Estimated pickup time
- Tracking availability status

### 5. Order Picked Up
**Trigger**: When driver picks up the order from merchant
**Purpose**: Inform customer that delivery is in progress

**Data Included**:
- Driver information
- Tracking URL
- Estimated delivery time

### 6. Order Out for Delivery
**Trigger**: When order is en route to customer
**Purpose**: Provide real-time delivery updates

**Data Included**:
- Tracking URL
- Estimated arrival time
- Real-time location updates

### 7. Order Delivered
**Trigger**: When order is successfully delivered
**Purpose**: Confirm delivery and request feedback

**Data Included**:
- Delivery timestamp
- Delivery notes
- Rating request prompt

### 8. Order Cancelled
**Trigger**: When order is cancelled by merchant or system
**Purpose**: Inform customer and provide refund information

**Data Included**:
- Cancellation reason
- Refund information
- Cancellation timestamp

### 9. Estimated Time Update
**Trigger**: When delivery/ready time estimates change
**Purpose**: Keep customer informed about delays or improvements

**Data Included**:
- New estimated time
- Reason for change
- Update timestamp

## API Reference

### Core Methods

#### send_customer_notification()

```python
async def send_customer_notification(
    self,
    order: Order,
    business: Business,
    notification_type: NotificationType,
    message: str,
    additional_data: Optional[Dict[str, Any]] = None
) -> bool
```

**Purpose**: Core method for sending any notification type
**Returns**: `True` if successful, `False` otherwise

**Payload Structure**:
```json
{
  "notification_type": "order_confirmed",
  "order_id": "uuid",
  "order_number": "ORD-123",
  "customer_info": {
    "customer_id": "customer_uuid",
    "customer_name": "John Doe",
    "customer_phone": "+1234567890",
    "customer_email": "john@example.com"
  },
  "business_info": {
    "business_id": "business_uuid",
    "business_name": "Restaurant Name",
    "business_type": "restaurant",
    "business_address": {...}
  },
  "order_details": {
    "status": "confirmed",
    "total_amount": 25.99,
    "delivery_type": "delivery",
    "estimated_delivery_time": "2025-06-25T18:30:00",
    "estimated_ready_time": "2025-06-25T18:00:00"
  },
  "message": "Great news! Restaurant has confirmed your order #ORD-123",
  "timestamp": "2025-06-25T17:30:00",
  "source": "order-receiver-app",
  "additional_data": {...}
}
```

#### Specific Notification Methods

##### notify_order_confirmed()
```python
async def notify_order_confirmed(
    self,
    order: Order,
    business: Business,
    notes: Optional[str] = None
) -> bool
```

##### notify_order_preparing()
```python
async def notify_order_preparing(
    self,
    order: Order,
    business: Business,
    estimated_ready_time: Optional[datetime] = None
) -> bool
```

##### notify_order_ready()
```python
async def notify_order_ready(
    self,
    order: Order,
    business: Business
) -> bool
```

##### notify_driver_assigned()
```python
async def notify_driver_assigned(
    self,
    order: Order,
    business: Business,
    driver_info: Dict[str, Any]
) -> bool
```

##### notify_order_picked_up()
```python
async def notify_order_picked_up(
    self,
    order: Order,
    business: Business,
    driver_info: Optional[Dict[str, Any]] = None
) -> bool
```

##### notify_order_out_for_delivery()
```python
async def notify_order_out_for_delivery(
    self,
    order: Order,
    business: Business,
    estimated_arrival: Optional[datetime] = None
) -> bool
```

##### notify_order_delivered()
```python
async def notify_order_delivered(
    self,
    order: Order,
    business: Business,
    delivery_notes: Optional[str] = None
) -> bool
```

##### notify_order_cancelled()
```python
async def notify_order_cancelled(
    self,
    order: Order,
    business: Business,
    reason: str,
    refund_info: Optional[Dict[str, Any]] = None
) -> bool
```

##### notify_estimated_time_update()
```python
async def notify_estimated_time_update(
    self,
    order: Order,
    business: Business,
    new_estimated_time: datetime,
    delay_reason: Optional[str] = None
) -> bool
```

### Utility Methods

#### send_push_notification()
```python
async def send_push_notification(
    self,
    customer_device_tokens: List[str],
    title: str,
    body: str,
    data: Optional[Dict[str, Any]] = None
) -> bool
```

**Purpose**: Send direct push notifications to customer devices
**Use Case**: Immediate, high-priority notifications

#### get_customer_tracking_info()
```python
async def get_customer_tracking_info(self, order_id: str) -> Optional[Dict[str, Any]]
```

**Purpose**: Retrieve real-time tracking information for orders
**Returns**: Tracking data or `None` if unavailable

## Configuration

### Environment Variables

```python
# Required configuration
CENTRALIZED_PLATFORM_URL=https://api.delivery-platform.com
CENTRALIZED_PLATFORM_API_KEY=your-secure-api-key

# Optional configuration
NOTIFICATION_TIMEOUT=10  # seconds
RETRY_ATTEMPTS=3
```

### Config Object Access
```python
from ..core.config import config

# Access in service
self.platform_base_url = getattr(config, 'centralized_platform_url', default_url)
self.api_key = getattr(config, 'centralized_platform_api_key', default_key)
```

## Usage Examples

### Basic Order Lifecycle

```python
from app.services.customer_notification_service import customer_notification_service

# 1. Order confirmed
await customer_notification_service.notify_order_confirmed(
    order=order,
    business=business,
    notes="Extra spicy as requested"
)

# 2. Start preparing
await customer_notification_service.notify_order_preparing(
    order=order,
    business=business,
    estimated_ready_time=datetime.now() + timedelta(minutes=25)
)

# 3. Order ready
await customer_notification_service.notify_order_ready(
    order=order,
    business=business
)

# 4. Driver assigned (for delivery orders)
driver_info = {
    "driver_id": "driver_123",
    "driver_name": "Mike Johnson",
    "driver_phone": "+1234567890",
    "vehicle_type": "Car",
    "estimated_pickup_time": "2025-06-25T18:15:00"
}
await customer_notification_service.notify_driver_assigned(
    order=order,
    business=business,
    driver_info=driver_info
)

# 5. Order picked up
await customer_notification_service.notify_order_picked_up(
    order=order,
    business=business,
    driver_info=driver_info
)

# 6. Out for delivery
await customer_notification_service.notify_order_out_for_delivery(
    order=order,
    business=business,
    estimated_arrival=datetime.now() + timedelta(minutes=15)
)

# 7. Delivered
await customer_notification_service.notify_order_delivered(
    order=order,
    business=business,
    delivery_notes="Left at front door as requested"
)
```

### Handling Delays

```python
# Notify about delay
new_time = datetime.now() + timedelta(minutes=30)
await customer_notification_service.notify_estimated_time_update(
    order=order,
    business=business,
    new_estimated_time=new_time,
    delay_reason="High order volume, thank you for your patience"
)
```

### Order Cancellation

```python
# Cancel order with refund
refund_info = {
    "refund_amount": order.total_amount,
    "refund_method": "original_payment",
    "processing_time": "3-5 business days"
}

await customer_notification_service.notify_order_cancelled(
    order=order,
    business=business,
    reason="Ingredient unavailable",
    refund_info=refund_info
)
```

### Direct Push Notifications

```python
# Send urgent notification
device_tokens = ["token1", "token2", "token3"]
await customer_notification_service.send_push_notification(
    customer_device_tokens=device_tokens,
    title="Order Update",
    body="Your order is running 10 minutes late",
    data={"order_id": str(order.id), "priority": "high"}
)
```

## Error Handling

### Network Errors
```python
try:
    success = await customer_notification_service.notify_order_confirmed(order, business)
    if not success:
        # Handle failed notification
        logger.warning(f"Failed to send confirmation for order {order.order_number}")
        # Implement retry logic or fallback notification
except Exception as e:
    logger.error(f"Notification service error: {e}")
    # Handle service unavailability
```

### Timeout Handling
- Default timeout: 10 seconds
- Automatic retry on timeout
- Graceful degradation if service unavailable

### Status Code Handling
- **200**: Success
- **400**: Bad request (check payload format)
- **401**: Unauthorized (check API key)
- **403**: Forbidden (check permissions)
- **500**: Server error (retry with backoff)

## Best Practices

### 1. Notification Timing
- Send confirmations immediately after order acceptance
- Use preparing notifications for longer preparation times (>15 minutes)
- Send ready notifications as soon as food is prepared
- Provide driver updates within 30 seconds of assignment

### 2. Message Quality
- Keep messages concise and customer-friendly
- Include specific time estimates when available
- Use business name for personalization
- Provide actionable information when possible

### 3. Error Recovery
```python
async def send_with_retry(notification_func, max_retries=3):
    for attempt in range(max_retries):
        try:
            success = await notification_func()
            if success:
                return True
        except Exception as e:
            if attempt == max_retries - 1:
                logger.error(f"Final retry failed: {e}")
                return False
            await asyncio.sleep(2 ** attempt)  # Exponential backoff
    return False
```

### 4. Performance Optimization
- Use connection pooling for HTTP requests
- Implement notification batching for multiple orders
- Cache business information to reduce payload size
- Use async/await for non-blocking operations

### 5. Testing
```python
# Mock the service for testing
from unittest.mock import AsyncMock

customer_notification_service.send_customer_notification = AsyncMock(return_value=True)

# Test notification flow
success = await customer_notification_service.notify_order_confirmed(order, business)
assert success is True
```

### 6. Monitoring
- Log all notification attempts with timestamps
- Track success/failure rates
- Monitor API response times
- Set up alerts for service downtime

### 7. Security
- Use HTTPS for all API communications
- Validate API keys regularly
- Sanitize customer data before transmission
- Implement rate limiting on notification endpoints

## Integration Points

### Order Management System
```python
# In order service
from app.services.customer_notification_service import customer_notification_service

async def confirm_order(order_id: str):
    order = await get_order(order_id)
    business = await get_business(order.business_id)
    
    # Update order status
    order.status = OrderStatus.CONFIRMED
    await save_order(order)
    
    # Send notification
    await customer_notification_service.notify_order_confirmed(order, business)
```

### Driver Management System
```python
# When driver is assigned
async def assign_driver(order_id: str, driver_id: str):
    order = await get_order(order_id)
    driver = await get_driver(driver_id)
    business = await get_business(order.business_id)
    
    # Update order with driver info
    order.assigned_driver_info = {
        "driver_id": driver.id,
        "driver_name": driver.name,
        "driver_phone": driver.phone,
        "vehicle_type": driver.vehicle_type
    }
    await save_order(order)
    
    # Send notification
    await customer_notification_service.notify_driver_assigned(
        order, business, order.assigned_driver_info
    )
```

## Troubleshooting

### Common Issues

1. **Notifications not sending**
   - Check API key configuration
   - Verify network connectivity
   - Validate payload format

2. **Timeout errors**
   - Increase timeout values
   - Check centralized platform status
   - Implement retry logic

3. **Customer not receiving notifications**
   - Verify customer device tokens
   - Check customer app notification settings
   - Validate order customer information

### Debug Mode
```python
# Enable debug logging
import logging
logging.getLogger('customer_notification_service').setLevel(logging.DEBUG)

# Check service configuration
service = CustomerNotificationService()
print(f"Platform URL: {service.platform_base_url}")
print(f"API Key configured: {bool(service.api_key and service.api_key != 'your-api-key')}")
```

## Global Instance

The service provides a global instance for easy access throughout the application:

```python
from app.services.customer_notification_service import customer_notification_service

# Use anywhere in the application
await customer_notification_service.notify_order_confirmed(order, business)
```

This documentation covers all aspects of the Customer Notification Service, providing developers with the information needed to effectively integrate and use the service in their applications.
