# Migration Guide: FastAPI to AWS Lambda Functions

This document outlines the migration from FastAPI web framework to pure AWS Lambda functions with API Gateway.

## Overview

The migration transforms the order receiver backend from:
- **From**: FastAPI web application running on uvicorn
- **To**: Serverless AWS Lambda functions with API Gateway and DynamoDB

## Architecture Changes

### Before (FastAPI)
```
Client → FastAPI App → In-memory Storage
```

### After (Serverless)
```
Client → API Gateway → Lambda Functions → DynamoDB
```

## Key Changes

### 1. Dependencies Removed
- `fastapi` - Web framework
- `uvicorn` - ASGI server
- `pydantic` - Data validation (replaced with native Python)

### 2. Dependencies Added
- `aws-lambda-powertools` - Production observability
- `boto3` - AWS SDK
- `email-validator` - Email validation

### 3. Handler Structure
**Before (FastAPI):**
```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/health")
def health():
    return {"status": "healthy"}
```

**After (Lambda):**
```python
def health(event, context):
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({"status": "healthy"})
    }
```

### 4. Data Storage
**Before:** In-memory dictionary
**After:** DynamoDB with GSI indexes

### 5. Configuration
**Before:** Environment variables and FastAPI settings
**After:** Serverless.yml and SAM template configurations

## File Structure

### New Files
- `lambda_functions/auth_lambda.py` - Pure Lambda auth handlers
- `lambda_functions/health_lambda.py` - Pure Lambda health handlers
- `lambda_functions/dynamodb_business_service.py` - DynamoDB service
- `lambda_functions/requirements-lambda.txt` - Serverless dependencies
- `serverless.yml` - Serverless Framework configuration
- `template.yaml` - AWS SAM template
- `package.json` - Node.js dependencies for Serverless
- `deploy.sh` - Serverless deployment script
- `deploy-sam.sh` - SAM deployment script
- `tests/test_lambda_functions.py` - Lambda-specific tests

### Legacy Files (to be removed)
- `app/` directory - FastAPI application
- Requirements.txt entries for FastAPI

## Deployment Options

### Option 1: Serverless Framework
```bash
# Install dependencies
npm install

# Deploy to dev environment
./deploy.sh dev

# Deploy to production
./deploy.sh prod
```

### Option 2: AWS SAM
```bash
# Deploy to dev environment
./deploy-sam.sh dev

# Deploy to production
./deploy-sam.sh prod
```

## Environment Variables

### Required Environment Variables
- `ENVIRONMENT` - Deployment environment (dev/staging/prod)
- `DYNAMODB_TABLE_NAME` - DynamoDB table name
- `AWS_REGION` - AWS region

### Auto-configured by Framework
- CloudWatch logging
- IAM permissions
- API Gateway endpoints

## API Endpoints

All endpoints remain the same:
- `GET /` - Root endpoint
- `GET /health` - Health check
- `GET /health/detailed` - Detailed health check
- `GET /auth/health` - Auth service health
- `POST /auth/register-business` - Business registration

## Testing

### Unit Tests
```bash
# Install test dependencies
pip install pytest moto

# Run Lambda-specific tests
python -m pytest tests/test_lambda_functions.py -v
```

### Integration Tests
```bash
# Test deployed endpoints
curl https://your-api-id.execute-api.us-east-1.amazonaws.com/dev/health
```

## Monitoring and Observability

### AWS Lambda Powertools Integration
- **Logging**: Structured JSON logging
- **Metrics**: Custom CloudWatch metrics
- **Tracing**: X-Ray distributed tracing

### CloudWatch Features
- Function logs in CloudWatch Logs
- Performance metrics
- Error tracking
- Cold start monitoring

## Performance Considerations

### Cold Starts
- Lambda functions may experience cold starts
- Minimized by keeping functions warm in production
- Lambda Powertools helps optimize performance

### Scaling
- Automatic scaling based on demand
- Pay-per-use pricing model
- No server management required

## Security

### IAM Permissions
- Least privilege access to DynamoDB
- CloudWatch logging permissions
- API Gateway integration permissions

### CORS Configuration
- Configurable per environment
- Restrictive settings for production

## Troubleshooting

### Common Issues

1. **DynamoDB Access Denied**
   - Check IAM permissions in serverless.yml
   - Verify table name environment variable

2. **CORS Errors**
   - Check CORS configuration in serverless.yml
   - Verify preflight requests handling

3. **Cold Start Timeouts**
   - Increase Lambda timeout in configuration
   - Consider provisioned concurrency for critical functions

### Debugging

```bash
# View function logs
serverless logs -f health --stage dev

# Local testing with SAM
sam local start-api

# Tail logs in real-time
serverless logs -f health --stage dev --tail
```

## Migration Checklist

- [x] Create pure Lambda handlers
- [x] Implement DynamoDB service
- [x] Configure serverless.yml
- [x] Configure SAM template
- [x] Create deployment scripts
- [x] Write Lambda-specific tests
- [x] Update documentation
- [ ] Remove FastAPI dependencies from main requirements.txt
- [ ] Archive or remove app/ directory
- [ ] Update CI/CD pipeline
- [ ] Test end-to-end functionality
- [ ] Update frontend API endpoints
- [ ] Monitor production deployment

## Rollback Plan

If issues occur, you can:
1. Keep the old FastAPI app directory intact during migration
2. Use blue-green deployment with Route 53
3. Maintain separate branches for FastAPI and Lambda versions

## Next Steps

1. **Clean up legacy code**: Remove FastAPI dependencies and app/ directory
2. **Update CI/CD**: Modify deployment pipeline for serverless
3. **Frontend updates**: Update API endpoint URLs
4. **Monitoring setup**: Configure CloudWatch alarms
5. **Performance optimization**: Fine-tune Lambda configurations
