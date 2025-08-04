# Central Platform Integration Guide
## Merchant App Backend Integration Information

This document provides all the necessary information for integrating your Central Platform with the deployed Merchant App Backend on AWS.

---

## 🔗 **API Endpoints & Integration Points**

### **Base URL**
```
https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev
```

### **1. Order Webhook Endpoint (Primary Integration)**
**Endpoint:** `POST /webhooks/orders`
**Purpose:** Send new orders from Central Platform to Merchant App Backend

**Request Format:**
```json
{
  "orderId": "string",           // Unique order ID from Central Platform
  "businessId": "string",        // Merchant/Business identifier
  "customerId": "string",        // Customer identifier
  "customerName": "string",      // Customer full name
  "customerPhone": "string",     // Customer phone number
  "deliveryAddress": {           // Delivery address object
    "street": "string",
    "city": "string",
    "state": "string",
    "zipCode": "string",
    "coordinates": {
      "lat": "number",
      "lng": "number"
    }
  },
  "items": [                     // Array of ordered items
    {
      "id": "string",
      "name": "string",
      "quantity": "number",
      "price": "number",
      "notes": "string"
    }
  ],
  "totalAmount": "number",       // Total order amount
  "notes": "string",             // Optional order notes
  "platformOrderId": "string"    // Reference ID in Central Platform
}
```

**Response Format:**
```json
{
  "success": true,
  "message": "Order received and processed successfully",
  "orderId": "string"
}
```

**Example Integration Code (Node.js):**
```javascript
const axios = require('axios');

const MERCHANT_BACKEND_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

async function sendOrderToMerchant(orderData) {
  try {
    const response = await axios.post(`${MERCHANT_BACKEND_URL}/webhooks/orders`, {
      orderId: orderData.id,
      businessId: orderData.restaurantId,
      customerId: orderData.customerId,
      customerName: orderData.customer.name,
      customerPhone: orderData.customer.phone,
      deliveryAddress: orderData.deliveryAddress,
      items: orderData.items,
      totalAmount: orderData.total,
      notes: orderData.specialInstructions,
      platformOrderId: orderData.id  // Your platform's order ID
    });
    
    console.log('Order sent to merchant successfully:', response.data);
    return response.data;
  } catch (error) {
    console.error('Failed to send order to merchant:', error.response?.data || error.message);
    throw error;
  }
}
```

---

## 📱 **Merchant App Status Update Callbacks**

### **Status Update Webhook (For Your Central Platform)**
You'll need to provide a webhook endpoint that the Merchant App Backend can call when order statuses change.

**Expected Callback Format:**
```json
POST {YOUR_CENTRAL_PLATFORM_WEBHOOK_URL}
Content-Type: application/json

{
  "orderId": "string",           // Merchant backend order ID
  "platformOrderId": "string",   // Your original order ID
  "businessId": "string",        // Merchant identifier
  "status": "string",            // New status (see statuses below)
  "timestamp": "string",         // ISO timestamp
  "estimatedPreparationTime": "number", // Minutes (for accepted orders)
  "rejectionReason": "string"    // Reason (for rejected orders)
}
```

**Order Status Flow:**
```
pending → accepted → preparing → ready → completed
       ↘ rejected
```

**Status Meanings:**
- `pending` - Order received, waiting for merchant response
- `accepted` - Merchant accepted the order
- `rejected` - Merchant rejected the order
- `preparing` - Merchant is preparing the order
- `ready` - Order is ready for pickup/delivery
- `completed` - Order has been completed

**Example Webhook Handler (Express.js):**
```javascript
app.post('/webhooks/merchant-order-status', async (req, res) => {
  try {
    const { orderId, platformOrderId, businessId, status, timestamp } = req.body;
    
    // Update order status in your database
    await updateOrderStatus(platformOrderId, {
      status: status,
      updatedAt: timestamp,
      merchantOrderId: orderId
    });
    
    // Notify customer app about status change
    await notifyCustomer(platformOrderId, status);
    
    // Notify driver app if needed
    if (status === 'ready') {
      await notifyDriver(platformOrderId);
    }
    
    res.json({ success: true, message: 'Status updated successfully' });
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});
```

---

## 🔄 **Order Management Flow**

### **Complete Integration Flow**
```
1. Customer places order on Central Platform
2. Central Platform → POST /webhooks/orders → Merchant Backend
3. Merchant Backend stores order & notifies Merchant App
4. Merchant accepts/rejects via Merchant App
5. Merchant Backend → POST /webhooks/merchant-status → Central Platform
6. Central Platform updates order status & notifies Customer/Driver
```

### **Error Handling & Retries**
Implement retry logic for webhook calls:

```javascript
async function sendWithRetry(url, data, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const response = await axios.post(url, data, { timeout: 10000 });
      return response.data;
    } catch (error) {
      console.log(`Attempt ${attempt} failed:`, error.message);
      
      if (attempt === maxRetries) {
        throw error;
      }
      
      // Exponential backoff
      await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempt) * 1000));
    }
  }
}
```

---

## 🏗️ **Database Schema Mapping**

### **Your Central Platform → Merchant Backend Mapping**
```javascript
// Your platform data structure → Merchant backend format
const orderMapping = {
  // Your field → Merchant backend field
  id: 'platformOrderId',
  restaurantId: 'businessId',
  customerId: 'customerId',
  'customer.name': 'customerName',
  'customer.phone': 'customerPhone',
  deliveryAddress: 'deliveryAddress',
  items: 'items',
  total: 'totalAmount',
  specialInstructions: 'notes'
};
```

### **Merchant Backend Order Schema**
```javascript
{
  orderId: String,              // Generated by merchant backend
  businessId: String,           // Your restaurant/merchant ID
  customerId: String,           // Your customer ID
  customerName: String,         // Customer name
  customerPhone: String,        // Customer phone
  deliveryAddress: Object,      // Address object
  items: Array,                // Order items
  totalAmount: Number,          // Order total
  status: String,              // Order status
  notes: String,               // Order notes
  platformOrderId: String,     // YOUR order ID (important!)
  estimatedPreparationTime: Number,
  rejectionReason: String,
  createdAt: String,           // ISO timestamp
  updatedAt: String            // ISO timestamp
}
```

---

## 🔐 **Authentication & Security**

### **API Security**
Currently using AWS IAM for some endpoints. For webhook endpoint:
- No authentication required for `/webhooks/orders`
- Consider implementing API key validation
- IP whitelisting recommended for production

### **Recommended Security Implementation**
```javascript
// Add API key validation
const MERCHANT_API_KEY = 'your-secure-api-key';

const headers = {
  'Content-Type': 'application/json',
  'X-API-Key': MERCHANT_API_KEY
};

await axios.post(url, data, { headers });
```

---

## 📊 **Monitoring & Logging**

### **CloudWatch Logs**
Monitor webhook calls in AWS CloudWatch:
```
Log Group: /aws/lambda/order-receiver-dev-merchant-orders-v1-sls
```

### **Health Check Endpoint**
```
GET https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/auth/health
```

Expected Response:
```json
{
  "success": true,
  "message": "Service is healthy",
  "timestamp": "2025-08-01T..."
}
```

---

## 🧪 **Testing Integration**

### **Test Order Webhook**
```bash
curl -X POST "https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/webhooks/orders" \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "test-order-123",
    "businessId": "test-business-456",
    "customerId": "test-customer-789",
    "customerName": "John Doe",
    "customerPhone": "+1234567890",
    "deliveryAddress": {
      "street": "123 Main St",
      "city": "New York",
      "state": "NY",
      "zipCode": "10001"
    },
    "items": [
      {
        "id": "item-1",
        "name": "Burger",
        "quantity": 2,
        "price": 15.99
      }
    ],
    "totalAmount": 31.98,
    "notes": "Extra sauce please",
    "platformOrderId": "platform-order-123"
  }'
```

### **Verify Order Storage**
```bash
curl -X GET "https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/merchant/orders/test-business-456"
```

---

## 🚀 **Deployment & Environment**

### **Current Environment**
- **Environment:** Development (`dev`)
- **Region:** `us-east-1`
- **Stage:** Ready for integration testing

### **Production Deployment**
When ready for production:
1. Deploy to `prod` stage
2. Update base URL to production endpoint
3. Configure production webhook URLs
4. Update API keys and security

---

## 📋 **Integration Checklist**

### **For Your Central Platform Team:**
- [ ] Implement webhook call to `/webhooks/orders`
- [ ] Create webhook endpoint for status updates
- [ ] Map your order data to merchant backend format
- [ ] Implement retry logic for failed webhook calls
- [ ] Add error handling and logging
- [ ] Test with sample orders
- [ ] Monitor webhook success rates
- [ ] Set up alerting for failed orders

### **Required Configuration:**
- [ ] Provide your webhook URL for status updates
- [ ] Configure API keys (optional but recommended)
- [ ] Set up IP whitelisting (recommended)
- [ ] Configure monitoring and alerting

---

## 📞 **Support & Troubleshooting**

### **Common Issues:**
1. **Order not appearing in merchant app:**
   - Check webhook response status
   - Verify businessId matches merchant account
   - Check CloudWatch logs

2. **Status updates not received:**
   - Verify webhook URL is accessible
   - Check webhook endpoint is responding with 200 status
   - Implement proper error handling

3. **Order format issues:**
   - Ensure all required fields are provided
   - Verify data types match expected format
   - Check for special characters in strings

### **Debug Commands:**
```bash
# Check recent webhook calls
aws logs filter-log-events \
  --log-group-name "/aws/lambda/order-receiver-dev-merchant-orders-v1-sls" \
  --start-time $(date -d '1 hour ago' +%s)000

# Test connectivity
curl -I https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/auth/health
```

---

## 🔄 **Next Steps**

1. **Immediate:** Test webhook integration with sample orders
2. **Short-term:** Implement status update webhook handling
3. **Medium-term:** Add comprehensive error handling and monitoring
4. **Long-term:** Plan production deployment and security hardening

---

**Contact Information:**
- **Environment:** AWS Lambda + API Gateway
- **Monitoring:** CloudWatch Logs
- **Documentation:** This integration guide
- **Status:** Ready for integration testing

This integration guide provides everything your Central Platform team needs to successfully integrate with the Merchant App Backend.
