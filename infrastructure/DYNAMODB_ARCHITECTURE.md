# AWS Serverless Architecture with DynamoDB
# Order Receiver Application - Serverless Stack

## Updated Architecture Overview

### Serverless Components:
- **AWS Lambda**: FastAPI backend functions
- **API Gateway**: REST API endpoint management  
- **DynamoDB**: NoSQL database for all data storage
- **Cognito**: User authentication and session management
- **S3 + CloudFront**: Frontend hosting
- **Lambda Layers**: Shared dependencies

### DynamoDB Table Design:

#### Single Table Design Pattern
**Main Table: `order-receiver-data`**

| Entity Type | Partition Key (PK) | Sort Key (SK) | Attributes |
|-------------|-------------------|---------------|------------|
| User | `USER#{user_id}` | `PROFILE` | email, phone, business_name, etc. |
| Business | `BUS#{business_id}` | `PROFILE` | name, type, address, settings |
| Item | `BUS#{business_id}` | `ITEM#{item_id}` | name, price, category, availability |
| Category | `BUS#{business_id}` | `CAT#{category_id}` | name, description, items_count |
| Order | `ORD#{order_id}` | `DETAILS` | customer, items, status, total |
| Order-Business | `BUS#{business_id}` | `ORD#{order_id}` | GSI access pattern |

#### Global Secondary Indexes (GSI):
1. **GSI1**: User lookup by email
   - PK: `email`, SK: `USER#{user_id}`
2. **GSI2**: Orders by business and status
   - PK: `BUS#{business_id}`, SK: `STATUS#{status}#CREATED#{timestamp}`

### Benefits of DynamoDB:
- **Serverless**: No infrastructure management
- **Auto-scaling**: Handles any load automatically
- **Performance**: Single-digit millisecond latency
- **Cost-effective**: Pay per request
- **Integration**: Native AWS service integration
