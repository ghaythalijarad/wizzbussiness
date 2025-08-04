# Technical API Specifications
## Merchant Backend API Documentation

---

## 📡 **API Base URL**
```
Development: https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev
Production: [To be configured]
```

---

## 🔐 **Authentication**
- **Webhook Endpoints:** No authentication required
- **Merchant Endpoints:** AWS IAM (for direct access)
- **Recommended:** API Key validation for production

---

## 📋 **API Endpoints Reference**

### **1. Order Webhook - Receive Orders from Central Platform**

**Endpoint:** `POST /webhooks/orders`
**Purpose:** Central Platform sends new orders to Merchant Backend
**Authentication:** None required

**Request Body Schema:**
```json
{
  "orderId": {
    "type": "string",
    "required": true,
    "description": "Unique order identifier from Central Platform",
    "example": "order_12345"
  },
  "businessId": {
    "type": "string", 
    "required": true,
    "description": "Merchant/Business identifier",
    "example": "merchant_abc123"
  },
  "customerId": {
    "type": "string",
    "required": true,
    "description": "Customer identifier",
    "example": "customer_xyz789"
  },
  "customerName": {
    "type": "string",
    "required": true,
    "description": "Customer full name",
    "example": "John Smith"
  },
  "customerPhone": {
    "type": "string",
    "required": true,
    "description": "Customer phone number",
    "example": "+1-555-123-4567"
  },
  "deliveryAddress": {
    "type": "object",
    "required": true,
    "properties": {
      "street": {"type": "string", "example": "123 Main Street"},
      "city": {"type": "string", "example": "New York"},
      "state": {"type": "string", "example": "NY"},
      "zipCode": {"type": "string", "example": "10001"},
      "coordinates": {
        "type": "object",
        "properties": {
          "lat": {"type": "number", "example": 40.7128},
          "lng": {"type": "number", "example": -74.0060}
        }
      }
    }
  },
  "items": {
    "type": "array",
    "required": true,
    "items": {
      "type": "object",
      "properties": {
        "id": {"type": "string", "example": "item_001"},
        "name": {"type": "string", "example": "Cheeseburger"},
        "quantity": {"type": "integer", "example": 2},
        "price": {"type": "number", "example": 12.99},
        "notes": {"type": "string", "example": "No onions"}
      }
    }
  },
  "totalAmount": {
    "type": "number",
    "required": true,
    "description": "Total order amount including tax and fees",
    "example": 28.47
  },
  "notes": {
    "type": "string",
    "required": false,
    "description": "Special instructions for the order",
    "example": "Please ring doorbell twice"
  },
  "platformOrderId": {
    "type": "string",
    "required": true,
    "description": "Original order ID in Central Platform (for reference)",
    "example": "central_platform_order_12345"
  }
}
```

**Response Schema:**
```json
{
  "success": {
    "type": "boolean",
    "description": "Operation success status"
  },
  "message": {
    "type": "string", 
    "description": "Human readable message"
  },
  "orderId": {
    "type": "string",
    "description": "Generated order ID in Merchant Backend"
  }
}
```

**Status Codes:**
- `201` - Order received and processed successfully
- `400` - Invalid request data
- `500` - Internal server error

**Example Request:**
```bash
curl -X POST "https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/webhooks/orders" \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "order_12345",
    "businessId": "restaurant_abc",
    "customerId": "customer_123",
    "customerName": "Jane Doe",
    "customerPhone": "+1-555-987-6543",
    "deliveryAddress": {
      "street": "456 Oak Avenue",
      "city": "Los Angeles", 
      "state": "CA",
      "zipCode": "90210",
      "coordinates": {
        "lat": 34.0522,
        "lng": -118.2437
      }
    },
    "items": [
      {
        "id": "pizza_margherita",
        "name": "Margherita Pizza",
        "quantity": 1,
        "price": 18.99,
        "notes": "Extra cheese"
      },
      {
        "id": "garlic_bread", 
        "name": "Garlic Bread",
        "quantity": 2,
        "price": 6.99
      }
    ],
    "totalAmount": 32.97,
    "notes": "Leave at door if no answer",
    "platformOrderId": "central_order_67890"
  }'
```

**Example Response:**
```json
{
  "success": true,
  "message": "Order received and processed successfully", 
  "orderId": "merchant_backend_order_98765"
}
```

---

### **2. Get Orders for Business**

**Endpoint:** `GET /merchant/orders/{businessId}`
**Purpose:** Retrieve orders for a specific merchant/business
**Authentication:** AWS IAM

**Path Parameters:**
- `businessId` (string, required): Merchant identifier

**Query Parameters:**
- `status` (string, optional): Filter by order status
  - Values: `pending`, `accepted`, `rejected`, `preparing`, `ready`, `completed`

**Response Schema:**
```json
{
  "success": {
    "type": "boolean"
  },
  "orders": {
    "type": "array",
    "items": {
      "type": "object",
      "properties": {
        "orderId": {"type": "string"},
        "businessId": {"type": "string"},
        "customerId": {"type": "string"},
        "customerName": {"type": "string"},
        "customerPhone": {"type": "string"},
        "deliveryAddress": {"type": "object"},
        "items": {"type": "array"},
        "totalAmount": {"type": "number"},
        "status": {"type": "string"},
        "notes": {"type": "string"},
        "platformOrderId": {"type": "string"},
        "createdAt": {"type": "string"},
        "updatedAt": {"type": "string"},
        "estimatedPreparationTime": {"type": "number"},
        "rejectionReason": {"type": "string"}
      }
    }
  },
  "count": {
    "type": "integer",
    "description": "Number of orders returned"
  }
}
```

**Example Request:**
```bash
curl -X GET "https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/merchant/orders/restaurant_abc?status=pending"
```

---

### **3. Accept Order**

**Endpoint:** `PUT /merchant/order/{orderId}/accept`
**Purpose:** Merchant accepts an order
**Authentication:** AWS IAM

**Path Parameters:**
- `orderId` (string, required): Order identifier

**Request Body Schema:**
```json
{
  "estimatedPreparationTime": {
    "type": "number",
    "required": false,
    "description": "Estimated time to prepare order in minutes",
    "default": 30,
    "example": 25
  }
}
```

**Response Schema:**
```json
{
  "success": {"type": "boolean"},
  "message": {"type": "string"},
  "order": {
    "type": "object",
    "description": "Updated order object with new status"
  }
}
```

**Example Request:**
```bash
curl -X PUT "https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/merchant/order/order_12345/accept" \
  -H "Content-Type: application/json" \
  -d '{"estimatedPreparationTime": 20}'
```

---

### **4. Reject Order**

**Endpoint:** `PUT /merchant/order/{orderId}/reject`
**Purpose:** Merchant rejects an order
**Authentication:** AWS IAM

**Path Parameters:**
- `orderId` (string, required): Order identifier

**Request Body Schema:**
```json
{
  "reason": {
    "type": "string",
    "required": false,
    "description": "Reason for rejecting the order",
    "example": "Out of ingredients"
  }
}
```

**Response Schema:**
```json
{
  "success": {"type": "boolean"},
  "message": {"type": "string"}, 
  "order": {
    "type": "object",
    "description": "Updated order object with rejected status"
  }
}
```

**Example Request:**
```bash
curl -X PUT "https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/merchant/order/order_12345/reject" \
  -H "Content-Type: application/json" \
  -d '{"reason": "Kitchen closed for maintenance"}'  
```

---

### **5. Update Order Status**

**Endpoint:** `PUT /merchant/order/{orderId}/status`
**Purpose:** Update order status (preparing, ready, etc.)
**Authentication:** AWS IAM

**Path Parameters:**
- `orderId` (string, required): Order identifier

**Request Body Schema:**
```json
{
  "status": {
    "type": "string",
    "required": true,
    "enum": ["preparing", "ready", "completed"],
    "description": "New order status"
  },
  "notes": {
    "type": "string",
    "required": false,
    "description": "Additional notes for status update",
    "example": "Food is ready for pickup"
  }
}
```

**Response Schema:**
```json
{
  "success": {"type": "boolean"},
  "message": {"type": "string"},
  "order": {
    "type": "object", 
    "description": "Updated order object"
  }
}
```

**Example Request:**
```bash
curl -X PUT "https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/merchant/order/order_12345/status" \
  -H "Content-Type: application/json" \
  -d '{"status": "ready", "notes": "Order is ready for pickup at counter"}'
```

---

### **6. Register Device Token**

**Endpoint:** `POST /merchants/{merchantId}/device-token`
**Purpose:** Register mobile device for push notifications
**Authentication:** AWS IAM

**Path Parameters:**
- `merchantId` (string, required): Merchant identifier

**Request Body Schema:**
```json
{
  "deviceToken": {
    "type": "string",
    "required": true,
    "description": "FCM or APNS device token",
    "example": "fcm_token_abc123..."
  },
  "platform": {
    "type": "string", 
    "required": true,
    "enum": ["ios", "android"],
    "description": "Mobile platform"
  }
}
```

**Response Schema:**
```json
{
  "success": {"type": "boolean"},
  "message": {"type": "string"}
}
```

**Example Request:**
```bash
curl -X POST "https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/merchants/restaurant_abc/device-token" \
  -H "Content-Type: application/json" \
  -d '{
    "deviceToken": "fcm_registration_token_here",
    "platform": "android"
  }'
```

---

### **7. Health Check**

**Endpoint:** `GET /auth/health`
**Purpose:** Service health check
**Authentication:** None

**Response Schema:**
```json
{
  "success": {"type": "boolean"},
  "message": {"type": "string"},
  "timestamp": {"type": "string"},
  "service": {"type": "string"}
}
```

**Example Request:**
```bash
curl -X GET "https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/auth/health"
```

---

## 🔄 **Webhook Callbacks (Status Updates)**

### **Status Update Callback (Your Central Platform Endpoint)**

When order status changes in the Merchant Backend, it will call your webhook:

**Your Endpoint:** `POST {YOUR_WEBHOOK_URL}`
**Content-Type:** `application/json`

**Payload Schema:**
```json
{
  "orderId": {
    "type": "string",
    "description": "Merchant backend order ID"
  },
  "platformOrderId": {
    "type": "string", 
    "description": "Your original order ID"
  },
  "businessId": {
    "type": "string",
    "description": "Merchant identifier"
  },
  "status": {
    "type": "string",
    "enum": ["accepted", "rejected", "preparing", "ready", "completed"],
    "description": "New order status"
  },
  "timestamp": {
    "type": "string",
    "format": "date-time",
    "description": "ISO 8601 timestamp"
  },
  "estimatedPreparationTime": {
    "type": "number",
    "description": "Minutes (only for accepted orders)"
  },
  "rejectionReason": {
    "type": "string",
    "description": "Reason (only for rejected orders)"
  }
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Status updated successfully"
}
```

---

## ❌ **Error Handling**

### **Standard Error Response Format:**
```json
{
  "success": false,
  "message": "Error description",
  "error": {
    "code": "ERROR_CODE",
    "details": "Additional error details"
  }
}
```

### **Common HTTP Status Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad Request (invalid data)
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

### **Error Codes:**
- `INVALID_REQUEST` - Request data validation failed
- `ORDER_NOT_FOUND` - Order ID not found
- `BUSINESS_NOT_FOUND` - Business ID not found
- `INVALID_STATUS` - Invalid status transition
- `PROCESSING_ERROR` - Internal processing error

---

## 🔧 **Rate Limits & Throttling**

### **Current Limits:**
- **Webhook calls:** No limit (recommended: 100 req/min)
- **API calls:** AWS Lambda concurrency limits apply
- **Timeout:** 29 seconds per request

### **Recommended Implementation:**
```javascript
// Implement exponential backoff for retries
const retryWithBackoff = async (fn, maxRetries = 3) => {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(resolve => 
        setTimeout(resolve, Math.pow(2, i) * 1000)
      );
    }
  }
};
```

---

## 📊 **Monitoring & Logging**

### **CloudWatch Logs:**
- Log Group: `/aws/lambda/order-receiver-dev-merchant-orders-v1-sls`
- Retention: 14 days
- Search by request ID for specific transactions

### **Metrics to Monitor:**
- Webhook success/failure rates
- Order processing latency
- Status update delivery rates
- Error rates by endpoint

### **Example Log Query:**
```bash
aws logs filter-log-events \
  --log-group-name "/aws/lambda/order-receiver-dev-merchant-orders-v1-sls" \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s)000
```

---

## 🧪 **Testing & Validation**

### **Integration Test Checklist:**
- [ ] Send test order via webhook
- [ ] Verify order appears in merchant backend
- [ ] Test order acceptance flow
- [ ] Test order rejection flow  
- [ ] Test status updates
- [ ] Verify webhook callbacks
- [ ] Test error scenarios
- [ ] Load test with multiple orders

### **Test Data Examples:**
Available in the integration guide and can be customized for your specific use case.

---

This technical specification provides comprehensive API documentation for integrating with the Merchant Backend system.
