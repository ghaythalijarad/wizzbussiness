# Order Receiver Serverless Backend

A serverless backend implementation using AWS Lambda, API Gateway, and DynamoDB for the Order Receiver application.

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐
│   Client    │───▶│  API Gateway    │───▶│ Lambda Functions│───▶│  DynamoDB   │
│ (Frontend)  │    │                 │    │                 │    │             │
└─────────────┘    └─────────────────┘    └─────────────────┘    └─────────────┘
```

### Components

- **API Gateway**: RESTful API endpoints with CORS support
- **Lambda Functions**: Serverless compute for business logic
- **DynamoDB**: NoSQL database with GSI indexes for fast queries
- **CloudWatch**: Logging, monitoring, and observability
- **IAM**: Security and access control

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- Node.js 18+ (for Serverless Framework)
- Python 3.9+
- Either Serverless Framework OR AWS SAM CLI

### Option 1: Serverless Framework Deployment

```bash
# Install Serverless Framework dependencies
npm install

# Deploy to development environment
./deploy.sh dev

# Deploy to production
./deploy.sh prod
```

### Option 2: AWS SAM Deployment

```bash
# Install SAM CLI if not already installed
pip install aws-sam-cli

# Deploy to development environment
./deploy-sam.sh dev

# Deploy to production
./deploy-sam.sh prod
```

## 📁 Project Structure

```
backend/
├── lambda_functions/           # Pure Lambda function handlers
│   ├── auth_lambda.py         # Authentication endpoints
│   ├── health_lambda.py       # Health check endpoints
│   ├── dynamodb_business_service.py  # DynamoDB operations
│   └── requirements-lambda.txt       # Serverless dependencies
├── tests/
│   └── test_lambda_functions.py      # Lambda-specific tests
├── serverless.yml             # Serverless Framework configuration
├── template.yaml             # AWS SAM template
├── package.json              # Node.js dependencies
├── deploy.sh                 # Serverless deployment script
├── deploy-sam.sh             # SAM deployment script
└── MIGRATION_GUIDE.md        # Migration documentation
```

## 🔗 API Endpoints

| Method | Endpoint                | Description              |
|--------|------------------------|--------------------------|
| GET    | `/`                    | Root endpoint            |
| GET    | `/health`              | Health check             |
| GET    | `/health/detailed`     | Detailed health check    |
| GET    | `/auth/health`         | Auth service health      |
| POST   | `/auth/register-business` | Register new business |

## 🧪 Testing

### Unit Tests

```bash
# Install test dependencies
pip install -r requirements.txt

# Run Lambda function tests
python -m pytest tests/test_lambda_functions.py -v

# Run all tests
npm run test:all
```

### Integration Testing

```bash
# Test deployed endpoints
export API_ENDPOINT="https://your-api-id.execute-api.us-east-1.amazonaws.com/dev"

# Health check
curl $API_ENDPOINT/health

# Auth health
curl $API_ENDPOINT/auth/health

# Register business
curl -X POST $API_ENDPOINT/auth/register-business \
  -H "Content-Type: application/json" \
  -d '{
    "business_name": "Test Business",
    "email": "test@example.com",
    "phone": "+1234567890",
    "address": "123 Test St",
    "cognito_user_id": "test-user-123"
  }'
```

## 🔧 Configuration

### Environment Variables

| Variable             | Description                | Default    |
|---------------------|----------------------------|------------|
| `ENVIRONMENT`       | Deployment environment     | `dev`      |
| `DYNAMODB_TABLE_NAME` | DynamoDB table name      | Auto-generated |
| `AWS_REGION`        | AWS region                 | `us-east-1` |
| `LOG_LEVEL`         | Logging level              | `INFO`     |

### Serverless Framework (serverless.yml)

- **Runtime**: Python 3.9
- **Memory**: 256MB
- **Timeout**: 30 seconds
- **Environment-specific CORS settings**
- **Rate limiting and throttling**

### AWS SAM (template.yaml)

- **API Gateway with tracing enabled**
- **Lambda functions with X-Ray tracing**
- **DynamoDB with point-in-time recovery (prod)**
- **Environment-specific configurations**

## 📊 Monitoring and Observability

### AWS Lambda Powertools

- **Structured JSON logging** with correlation IDs
- **Custom CloudWatch metrics** for business insights
- **X-Ray distributed tracing** for performance analysis

### CloudWatch Features

- Function execution logs
- Performance metrics (duration, memory usage)
- Error rates and cold start metrics
- Custom dashboards

### Accessing Logs

```bash
# Serverless Framework
serverless logs -f health --stage dev --tail

# AWS CLI
aws logs tail /aws/lambda/order-receiver-health-dev --follow

# SAM CLI
sam logs --stack-name order-receiver-serverless-dev
```

## 🔒 Security

### IAM Permissions

Lambda functions have minimal required permissions:
- DynamoDB read/write access to business table
- CloudWatch logs write access
- X-Ray tracing permissions

### CORS Configuration

- Development: Permissive CORS for testing
- Production: Restrictive CORS with specific origins

### Data Validation

- Email format validation
- Required field validation
- Input sanitization

## 🚀 Performance

### Cold Start Optimization

- Minimal dependencies in Lambda packages
- Connection pooling for DynamoDB
- Lambda Powertools for optimal performance

### Scaling

- Automatic scaling based on request volume
- Concurrent execution limits configurable
- DynamoDB auto-scaling enabled

## 🛠️ Development

### Local Development

```bash
# Serverless offline (simulates API Gateway + Lambda)
npm run local

# SAM local (alternative)
sam local start-api
```

### Adding New Endpoints

1. **Create handler function** in appropriate Lambda file
2. **Add endpoint configuration** in serverless.yml or template.yaml
3. **Write tests** in test_lambda_functions.py
4. **Deploy and test**

### Environment Management

- **dev**: Development with relaxed CORS and lower rate limits
- **staging**: Production-like with moderate rate limits
- **prod**: Production with strict CORS and high rate limits

## 📈 Scaling and Costs

### Scaling Characteristics

- **API Gateway**: Handles millions of requests
- **Lambda**: Auto-scales to handle concurrent requests
- **DynamoDB**: On-demand billing scales automatically

### Cost Optimization

- Pay-per-use model (no idle costs)
- DynamoDB on-demand billing
- Lambda provisioned concurrency for critical functions (optional)

## 🔄 Migration from FastAPI

This backend was migrated from FastAPI. See [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md) for detailed migration information.

### Key Benefits of Migration

- **Zero server management**
- **Automatic scaling**
- **Pay-per-use pricing**
- **High availability**
- **Better observability**

## 🆘 Troubleshooting

### Common Issues

**DynamoDB Permission Errors**
```bash
# Check IAM permissions in serverless.yml or template.yaml
# Verify table name in environment variables
```

**CORS Errors**
```bash
# Check CORS configuration
# Verify preflight request handling
```

**Cold Start Performance**
```bash
# Consider provisioned concurrency for critical functions
# Optimize function package size
```

### Debug Commands

```bash
# View function configuration
aws lambda get-function --function-name order-receiver-health-dev

# Check DynamoDB table
aws dynamodb describe-table --table-name order-receiver-businesses-dev

# View API Gateway
aws apigateway get-rest-apis
```

## 📚 Additional Resources

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/)
- [Serverless Framework Documentation](https://www.serverless.com/framework/docs/)
- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
