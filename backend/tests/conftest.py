"""
Test configuration and fixtures
"""

import pytest
import os
import boto3
from moto import mock_aws


@pytest.fixture(scope="session")
def aws_credentials():
    """Mocked AWS Credentials for moto."""
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"


@pytest.fixture
def dynamodb_table(aws_credentials):
    """Create a mock DynamoDB table for testing"""
    with mock_aws():
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        
        table = dynamodb.create_table(
            TableName='order-receiver-test',
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
        
        yield table


@pytest.fixture
def cognito_client(aws_credentials):
    """Create a mock Cognito client for testing"""
    with mock_aws():
        client = boto3.client('cognito-idp', region_name='us-east-1')
        
        # Create user pool
        user_pool = client.create_user_pool(
            PoolName='test-pool',
            Policies={
                'PasswordPolicy': {
                    'MinimumLength': 8,
                    'RequireUppercase': True,
                    'RequireLowercase': True,
                    'RequireNumbers': True,
                    'RequireSymbols': False,
                }
            }
        )
        
        # Create user pool client
        user_pool_client = client.create_user_pool_client(
            UserPoolId=user_pool['UserPool']['Id'],
            ClientName='test-client'
        )
        
        yield {
            'client': client,
            'user_pool_id': user_pool['UserPool']['Id'],
            'client_id': user_pool_client['UserPoolClient']['ClientId']
        }


@pytest.fixture
def sample_order():
    """Sample order data for testing"""
    return {
        'customer_name': 'Test Customer',
        'customer_email': 'test@example.com',
        'items': [
            {
                'name': 'Test Item 1',
                'quantity': 2,
                'price': 15.99,
                'category': 'food'
            },
            {
                'name': 'Test Item 2',
                'quantity': 1,
                'price': 8.50,
                'category': 'beverage'
            }
        ],
        'total_amount': 40.48,
        'payment_method': 'credit_card',
        'delivery_address': {
            'street': '123 Test St',
            'city': 'Test City',
            'zipcode': '12345'
        }
    }


@pytest.fixture
def api_headers():
    """Standard API headers for testing"""
    return {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
