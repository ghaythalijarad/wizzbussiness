"""
Unit tests for Lambda functions - replacing FastAPI tests
"""

import pytest
import json
import os
import sys
from unittest.mock import Mock, patch, MagicMock
import boto3
from moto import mock_dynamodb

# Add the lambda_functions directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'lambda_functions'))

# Import our Lambda handlers
from auth_lambda import auth_health, register_business
from health_lambda import root, health, health_detailed
from dynamodb_business_service import DynamoDBBusinessService


class TestHealthLambdaFunctions:
    """Test cases for health check Lambda functions"""
    
    def test_root_endpoint(self):
        """Test the root endpoint Lambda function"""
        event = {
            'httpMethod': 'GET',
            'path': '/',
            'headers': {},
            'queryStringParameters': None,
            'body': None
        }
        context = Mock()
        
        response = root(event, context)
        
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['message'] == 'Order Receiver API - Serverless Lambda Version'
        assert 'timestamp' in body
        
    def test_health_endpoint(self):
        """Test the health check endpoint"""
        event = {
            'httpMethod': 'GET',
            'path': '/health',
            'headers': {},
            'queryStringParameters': None,
            'body': None
        }
        context = Mock()
        
        response = health(event, context)
        
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['status'] == 'healthy'
        assert 'timestamp' in body
        
    def test_health_detailed_endpoint(self):
        """Test the detailed health check endpoint"""
        event = {
            'httpMethod': 'GET',
            'path': '/health/detailed',
            'headers': {},
            'queryStringParameters': None,
            'body': None
        }
        context = Mock()
        
        with patch.dict(os.environ, {
            'ENVIRONMENT': 'test',
            'AWS_REGION': 'us-east-1',
            'DYNAMODB_TABLE_NAME': 'test-table'
        }):
            response = health_detailed(event, context)
        
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['status'] == 'healthy'
        assert body['environment'] == 'test'
        assert body['region'] == 'us-east-1'
        assert 'timestamp' in body


class TestAuthLambdaFunctions:
    """Test cases for authentication Lambda functions"""
    
    def test_auth_health_endpoint(self):
        """Test the auth health check endpoint"""
        event = {
            'httpMethod': 'GET',
            'path': '/auth/health',
            'headers': {},
            'queryStringParameters': None,
            'body': None
        }
        context = Mock()
        
        response = auth_health(event, context)
        
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['service'] == 'auth'
        assert body['status'] == 'healthy'
        assert 'timestamp' in body
    
    @mock_dynamodb
    def test_register_business_success(self):
        """Test successful business registration"""
        # Setup DynamoDB mock
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        table_name = 'test-businesses'
        
        table = dynamodb.create_table(
            TableName=table_name,
            KeySchema=[
                {'AttributeName': 'business_id', 'KeyType': 'HASH'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'business_id', 'AttributeType': 'S'},
                {'AttributeName': 'cognito_user_id', 'AttributeType': 'S'},
                {'AttributeName': 'email', 'AttributeType': 'S'}
            ],
            GlobalSecondaryIndexes=[
                {
                    'IndexName': 'cognito-user-index',
                    'KeySchema': [
                        {'AttributeName': 'cognito_user_id', 'KeyType': 'HASH'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'},
                    'BillingMode': 'PAY_PER_REQUEST'
                },
                {
                    'IndexName': 'email-index',
                    'KeySchema': [
                        {'AttributeName': 'email', 'KeyType': 'HASH'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'},
                    'BillingMode': 'PAY_PER_REQUEST'
                }
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        
        event = {
            'httpMethod': 'POST',
            'path': '/auth/register-business',
            'headers': {'Content-Type': 'application/json'},
            'queryStringParameters': None,
            'body': json.dumps({
                'business_name': 'Test Business',
                'email': 'test@example.com',
                'phone': '+1234567890',
                'address': '123 Test St',
                'cognito_user_id': 'test-user-123'
            })
        }
        context = Mock()
        
        with patch.dict(os.environ, {'DYNAMODB_TABLE_NAME': table_name}):
            response = register_business(event, context)
        
        assert response['statusCode'] == 201
        body = json.loads(response['body'])
        assert body['message'] == 'Business registered successfully'
        assert 'business_id' in body
        
    def test_register_business_missing_fields(self):
        """Test business registration with missing required fields"""
        event = {
            'httpMethod': 'POST',
            'path': '/auth/register-business',
            'headers': {'Content-Type': 'application/json'},
            'queryStringParameters': None,
            'body': json.dumps({
                'business_name': 'Test Business'
                # Missing required fields
            })
        }
        context = Mock()
        
        response = register_business(event, context)
        
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert 'error' in body
        
    def test_register_business_invalid_email(self):
        """Test business registration with invalid email"""
        event = {
            'httpMethod': 'POST',
            'path': '/auth/register-business',
            'headers': {'Content-Type': 'application/json'},
            'queryStringParameters': None,
            'body': json.dumps({
                'business_name': 'Test Business',
                'email': 'invalid-email',  # Invalid email format
                'phone': '+1234567890',
                'address': '123 Test St',
                'cognito_user_id': 'test-user-123'
            })
        }
        context = Mock()
        
        response = register_business(event, context)
        
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert 'error' in body
        assert 'email' in body['error'].lower()


@mock_dynamodb
class TestDynamoDBBusinessService:
    """Test cases for DynamoDB business service"""
    
    def setup_method(self):
        """Set up test fixtures"""
        self.dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        self.table_name = 'test-businesses'
        
        # Create test table
        self.table = self.dynamodb.create_table(
            TableName=self.table_name,
            KeySchema=[
                {'AttributeName': 'business_id', 'KeyType': 'HASH'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'business_id', 'AttributeType': 'S'},
                {'AttributeName': 'cognito_user_id', 'AttributeType': 'S'},
                {'AttributeName': 'email', 'AttributeType': 'S'}
            ],
            GlobalSecondaryIndexes=[
                {
                    'IndexName': 'cognito-user-index',
                    'KeySchema': [
                        {'AttributeName': 'cognito_user_id', 'KeyType': 'HASH'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'},
                    'BillingMode': 'PAY_PER_REQUEST'
                },
                {
                    'IndexName': 'email-index',
                    'KeySchema': [
                        {'AttributeName': 'email', 'KeyType': 'HASH'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'},
                    'BillingMode': 'PAY_PER_REQUEST'
                }
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        
        self.service = DynamoDBBusinessService(self.table_name)
    
    def test_create_business(self):
        """Test creating a business in DynamoDB"""
        business_data = {
            'business_name': 'Test Business',
            'email': 'test@example.com',
            'phone': '+1234567890',
            'address': '123 Test St',
            'cognito_user_id': 'test-user-123'
        }
        
        business_id = self.service.create_business(business_data)
        
        assert business_id is not None
        assert isinstance(business_id, str)
        assert len(business_id) > 0
    
    def test_get_business_by_id(self):
        """Test retrieving a business by ID"""
        business_data = {
            'business_name': 'Test Business',
            'email': 'test@example.com',
            'phone': '+1234567890',
            'address': '123 Test St',
            'cognito_user_id': 'test-user-123'
        }
        
        business_id = self.service.create_business(business_data)
        retrieved_business = self.service.get_business_by_id(business_id)
        
        assert retrieved_business is not None
        assert retrieved_business['business_id'] == business_id
        assert retrieved_business['business_name'] == business_data['business_name']
        assert retrieved_business['email'] == business_data['email']
    
    def test_get_business_by_email(self):
        """Test retrieving a business by email"""
        business_data = {
            'business_name': 'Test Business',
            'email': 'test@example.com',
            'phone': '+1234567890',
            'address': '123 Test St',
            'cognito_user_id': 'test-user-123'
        }
        
        business_id = self.service.create_business(business_data)
        retrieved_business = self.service.get_business_by_email(business_data['email'])
        
        assert retrieved_business is not None
        assert retrieved_business['business_id'] == business_id
        assert retrieved_business['email'] == business_data['email']
    
    def test_get_business_by_cognito_user_id(self):
        """Test retrieving a business by Cognito user ID"""
        business_data = {
            'business_name': 'Test Business',
            'email': 'test@example.com',
            'phone': '+1234567890',
            'address': '123 Test St',
            'cognito_user_id': 'test-user-123'
        }
        
        business_id = self.service.create_business(business_data)
        retrieved_business = self.service.get_business_by_cognito_user_id(business_data['cognito_user_id'])
        
        assert retrieved_business is not None
        assert retrieved_business['business_id'] == business_id
        assert retrieved_business['cognito_user_id'] == business_data['cognito_user_id']
    
    def test_business_not_found(self):
        """Test retrieving a non-existent business"""
        assert self.service.get_business_by_id('non-existent-id') is None
        assert self.service.get_business_by_email('nonexistent@example.com') is None
        assert self.service.get_business_by_cognito_user_id('non-existent-user') is None


if __name__ == '__main__':
    pytest.main([__file__])
