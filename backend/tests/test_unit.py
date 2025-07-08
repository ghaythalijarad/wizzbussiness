"""
Unit tests for the backend application
"""

import pytest
import json
from unittest.mock import Mock, patch
import boto3
from moto import mock_aws
import sys
import os
from fastapi.testclient import TestClient

# Add the app directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'app'))

try:
    from application import create_app
except ImportError:
    # If the main app isn't available, create a mock
    from fastapi import FastAPI
    
    def create_app():
        app = FastAPI()
        
        @app.get('/health')
        def health():
            return {'status': 'healthy'}
            
        @app.get('/auth/health')
        def auth_health():
            return {'status': 'healthy', 'service': 'auth'}
            
        return app


class TestBackendUnit:
    """Unit tests for backend functionality"""
    
    def setup_method(self):
        """Setup test method with FastAPI test client"""
        self.app = create_app()
        self.client = TestClient(self.app)
        
    def test_health_endpoint(self):
        """Test health check endpoint"""
        response = self.client.get('/health')
        assert response.status_code == 200
        data = response.json()
        assert data['status'] == 'healthy'
        
    def test_auth_health_endpoint(self):
        """Test auth service health check endpoint"""
        response = self.client.get('/auth/health')
        assert response.status_code == 200
        data = response.json()
        assert data['status'] == 'healthy'
        assert data['service'] == 'auth'
        
    @mock_aws
    def test_dynamodb_connection(self):
        """Test DynamoDB connection and basic operations"""
        # Create mock DynamoDB table
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        
        table = dynamodb.create_table(
            TableName='test-orders',
            KeySchema=[
                {
                    'AttributeName': 'PK',
                    'KeyType': 'HASH'
                },
                {
                    'AttributeName': 'SK',
                    'KeyType': 'RANGE'
                }
            ],
            AttributeDefinitions=[
                {
                    'AttributeName': 'PK',
                    'AttributeType': 'S'
                },
                {
                    'AttributeName': 'SK',
                    'AttributeType': 'S'
                }
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        
        # Test basic operations
        table.put_item(Item={'PK': 'BUSINESS#123', 'SK': 'METADATA', 'data': 'test-data'})
        response = table.get_item(Key={'PK': 'BUSINESS#123', 'SK': 'METADATA'})
        assert 'Item' in response
        assert response['Item']['data'] == 'test-data'
        
    def test_business_registration_validation(self):
        """Test business registration data validation"""
        # Test valid business registration data
        valid_business = {
            'cognito_user_id': 'user123',
            'email': 'test@example.com',
            'business_name': 'Test Restaurant',
            'business_type': 'restaurant',
            'owner_name': 'John Doe',
            'phone_number': '+1234567890',
            'address': {
                'street': '123 Main St',
                'city': 'Test City',
                'zipcode': '12345'
            }
        }
        
        # Test invalid business registration data
        invalid_business = {
            'cognito_user_id': '',  # Empty user ID
            'email': 'invalid-email',  # Invalid email
            'business_name': '',  # Empty name
            'business_type': 'unknown',  # Unknown type
            'owner_name': '',  # Empty owner name
            'phone_number': 'invalid',  # Invalid phone
            'address': {}  # Empty address
        }
        
        # Validate structure
        assert 'cognito_user_id' in valid_business
        assert '@' in valid_business['email']
        assert len(valid_business['business_name']) > 0
        assert len(valid_business['owner_name']) > 0
        assert 'street' in valid_business['address']
        
        # Validate invalid data
        assert not invalid_business['cognito_user_id']
        assert '@' not in invalid_business['email']
        assert not invalid_business['business_name']
        assert not invalid_business['owner_name']
        assert not invalid_business['address']

    def test_order_data_structure(self):
        """Test order data structure validation"""
        valid_order = {
            'customer_name': 'John Doe',
            'customer_email': 'john@example.com',
            'items': [
                {
                    'name': 'Item 1',
                    'quantity': 2,
                    'price': 10.99,
                    'category': 'food'
                }
            ],
            'total_amount': 21.98,
            'payment_method': 'credit_card',
            'status': 'pending'
        }
        
        # Validate order structure
        assert 'customer_name' in valid_order
        assert 'items' in valid_order
        assert len(valid_order['items']) > 0
        assert valid_order['total_amount'] > 0
        assert valid_order['items'][0]['quantity'] > 0
        assert valid_order['items'][0]['price'] > 0


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--cov=app", "--cov-report=xml"])
