"""
AWS Cognito Authentication Lambda handlers for login functionality.
Pure serverless implementation for user authentication.
"""
import json
import os
import boto3
from datetime import datetime
from typing import Dict, Any
from botocore.exceptions import ClientError

# AWS Lambda Powertools for production-ready observability
try:
    from aws_lambda_powertools import Logger, Tracer, Metrics
    from aws_lambda_powertools.logging import correlation_paths
    from aws_lambda_powertools.metrics import MetricUnit
    
    # Initialize AWS Lambda Powertools
    logger = Logger()
    tracer = Tracer()
    metrics = Metrics()
    powertools_available = True
except ImportError:
    # Fallback to standard logging if powertools not available
    import logging
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)
    powertools_available = False

# Initialize Cognito client
cognito_client = boto3.client('cognito-idp')

# Get Cognito configuration from environment
USER_POOL_ID = os.environ.get('COGNITO_USER_POOL_ID')
CLIENT_ID = os.environ.get('COGNITO_CLIENT_ID')

def lambda_response(status_code: int, body: Dict[str, Any], headers: Dict[str, str] = None) -> Dict[str, Any]:
    """Helper function to create standardized Lambda response for API Gateway."""
    if headers is None:
        headers = {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        }
    
    return {
        'statusCode': status_code,
        'headers': headers,
        'body': json.dumps(body, default=str)
    }

def cognito_login(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Handle user login using AWS Cognito.
    Expected request body: {"email": "user@example.com", "password": "password123"}
    """
    if powertools_available:
        metrics.add_metric(name="CognitoLoginAttempt", unit=MetricUnit.Count, value=1)
    
    try:
        # Parse request body
        body = event.get('body', '{}')
        if isinstance(body, str):
            request_data = json.loads(body)
        else:
            request_data = body
        
        email = request_data.get('email')
        password = request_data.get('password')
        
        if not email or not password:
            if powertools_available:
                metrics.add_metric(name="CognitoLoginValidationError", unit=MetricUnit.Count, value=1)
            return lambda_response(400, {
                'success': False,
                'message': 'Email and password are required'
            })
        
        # Attempt authentication with Cognito
        try:
            response = cognito_client.admin_initiate_auth(
                UserPoolId=USER_POOL_ID,
                ClientId=CLIENT_ID,
                AuthFlow='ADMIN_NO_SRP_AUTH',
                AuthParameters={
                    'USERNAME': email,
                    'PASSWORD': password
                }
            )
            
            # Extract tokens from Cognito response
            auth_result = response.get('AuthenticationResult', {})
            access_token = auth_result.get('AccessToken')
            id_token = auth_result.get('IdToken')
            refresh_token = auth_result.get('RefreshToken')
            
            if powertools_available:
                metrics.add_metric(name="CognitoLoginSuccess", unit=MetricUnit.Count, value=1)
                logger.info("Cognito login successful", extra={"email": email})
            
            return lambda_response(200, {
                'success': True,
                'message': 'Login successful',
                'access_token': access_token,
                'id_token': id_token,
                'refresh_token': refresh_token,
                'token_type': 'Bearer'
            })
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            
            if powertools_available:
                metrics.add_metric(name="CognitoLoginError", unit=MetricUnit.Count, value=1)
                logger.warning("Cognito login failed", extra={"email": email, "error_code": error_code})
            
            if error_code == 'NotAuthorizedException':
                return lambda_response(401, {
                    'success': False,
                    'message': 'Invalid email or password'
                })
            elif error_code == 'UserNotConfirmedException':
                return lambda_response(403, {
                    'success': False,
                    'message': 'Email not verified. Please check your email for verification instructions.'
                })
            elif error_code == 'UserNotFoundException':
                return lambda_response(404, {
                    'success': False,
                    'message': 'User not found. Please register first.'
                })
            else:
                return lambda_response(500, {
                    'success': False,
                    'message': f'Authentication error: {error_code}'
                })
                
    except json.JSONDecodeError:
        if powertools_available:
            metrics.add_metric(name="CognitoLoginJSONError", unit=MetricUnit.Count, value=1)
        return lambda_response(400, {
            'success': False,
            'message': 'Invalid JSON in request body'
        })
    except Exception as e:
        if powertools_available:
            metrics.add_metric(name="CognitoLoginSystemError", unit=MetricUnit.Count, value=1)
            logger.exception("Unexpected error in Cognito login")
        
        return lambda_response(500, {
            'success': False,
            'message': 'Internal server error'
        })

def cognito_register(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Handle user registration using AWS Cognito.
    Expected request body: {"email": "user@example.com", "password": "password123", "userData": {...}}
    """
    if powertools_available:
        metrics.add_metric(name="CognitoRegisterAttempt", unit=MetricUnit.Count, value=1)
    
    try:
        # Parse request body
        body = event.get('body', '{}')
        if isinstance(body, str):
            request_data = json.loads(body)
        else:
            request_data = body
        
        email = request_data.get('email')
        password = request_data.get('password')
        user_data = request_data.get('userData', {})
        
        if not email or not password:
            if powertools_available:
                metrics.add_metric(name="CognitoRegisterValidationError", unit=MetricUnit.Count, value=1)
            return lambda_response(400, {
                'success': False,
                'message': 'Email and password are required'
            })
        
        # Prepare user attributes
        user_attributes = [
            {'Name': 'email', 'Value': email},
            {'Name': 'email_verified', 'Value': 'false'},
        ]
        
        # Add additional user attributes from userData
        for key, value in user_data.items():
            if key not in ['email', 'password'] and value:
                user_attributes.append({'Name': key, 'Value': str(value)})
        
        # Attempt registration with Cognito
        try:
            response = cognito_client.admin_create_user(
                UserPoolId=USER_POOL_ID,
                Username=email,
                UserAttributes=user_attributes,
                TemporaryPassword=password,
                MessageAction='SUPPRESS'  # Don't send welcome email
            )
            
            # Set permanent password
            cognito_client.admin_set_user_password(
                UserPoolId=USER_POOL_ID,
                Username=email,
                Password=password,
                Permanent=True
            )
            
            if powertools_available:
                metrics.add_metric(name="CognitoRegisterSuccess", unit=MetricUnit.Count, value=1)
                logger.info("Cognito registration successful", extra={"email": email})
            
            return lambda_response(201, {
                'success': True,
                'message': 'Registration successful. Please verify your email.',
                'user_id': response['User']['Username'],
                'email_verification_required': True
            })
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            
            if powertools_available:
                metrics.add_metric(name="CognitoRegisterError", unit=MetricUnit.Count, value=1)
                logger.warning("Cognito registration failed", extra={"email": email, "error_code": error_code})
            
            if error_code == 'UsernameExistsException':
                return lambda_response(409, {
                    'success': False,
                    'message': 'User already exists with this email'
                })
            elif error_code == 'InvalidPasswordException':
                return lambda_response(400, {
                    'success': False,
                    'message': 'Password does not meet requirements'
                })
            else:
                return lambda_response(500, {
                    'success': False,
                    'message': f'Registration error: {error_code}'
                })
                
    except json.JSONDecodeError:
        if powertools_available:
            metrics.add_metric(name="CognitoRegisterJSONError", unit=MetricUnit.Count, value=1)
        return lambda_response(400, {
            'success': False,
            'message': 'Invalid JSON in request body'
        })
    except Exception as e:
        if powertools_available:
            metrics.add_metric(name="CognitoRegisterSystemError", unit=MetricUnit.Count, value=1)
            logger.exception("Unexpected error in Cognito registration")
        
        return lambda_response(500, {
            'success': False,
            'message': 'Internal server error'
        })

def cognito_verify_email(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Handle email verification using AWS Cognito.
    Expected request body: {"email": "user@example.com", "verification_code": "123456"}
    """
    if powertools_available:
        metrics.add_metric(name="CognitoVerifyAttempt", unit=MetricUnit.Count, value=1)
    
    try:
        # Parse request body
        body = event.get('body', '{}')
        if isinstance(body, str):
            request_data = json.loads(body)
        else:
            request_data = body
        
        email = request_data.get('email')
        verification_code = request_data.get('verification_code')
        
        if not email or not verification_code:
            if powertools_available:
                metrics.add_metric(name="CognitoVerifyValidationError", unit=MetricUnit.Count, value=1)
            return lambda_response(400, {
                'success': False,
                'message': 'Email and verification code are required'
            })
        
        # Confirm user signup
        try:
            cognito_client.admin_confirm_sign_up(
                UserPoolId=USER_POOL_ID,
                Username=email
            )
            
            if powertools_available:
                metrics.add_metric(name="CognitoVerifySuccess", unit=MetricUnit.Count, value=1)
                logger.info("Email verification successful", extra={"email": email})
            
            return lambda_response(200, {
                'success': True,
                'message': 'Email verified successfully. You can now login.'
            })
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            
            if powertools_available:
                metrics.add_metric(name="CognitoVerifyError", unit=MetricUnit.Count, value=1)
                logger.warning("Email verification failed", extra={"email": email, "error_code": error_code})
            
            if error_code == 'CodeMismatchException':
                return lambda_response(400, {
                    'success': False,
                    'message': 'Invalid verification code'
                })
            elif error_code == 'ExpiredCodeException':
                return lambda_response(400, {
                    'success': False,
                    'message': 'Verification code has expired'
                })
            else:
                return lambda_response(500, {
                    'success': False,
                    'message': f'Verification error: {error_code}'
                })
                
    except json.JSONDecodeError:
        if powertools_available:
            metrics.add_metric(name="CognitoVerifyJSONError", unit=MetricUnit.Count, value=1)
        return lambda_response(400, {
            'success': False,
            'message': 'Invalid JSON in request body'
        })
    except Exception as e:
        if powertools_available:
            metrics.add_metric(name="CognitoVerifySystemError", unit=MetricUnit.Count, value=1)
            logger.exception("Unexpected error in email verification")
        
        return lambda_response(500, {
            'success': False,
            'message': 'Internal server error'
        })

def cognito_health(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Health check for Cognito authentication service."""
    return lambda_response(200, {
        'service': 'cognito-auth',
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'environment': os.environ.get('ENVIRONMENT', 'dev'),
        'user_pool_id': USER_POOL_ID,
        'region': os.environ.get('AWS_DEFAULT_REGION', 'us-east-1'),
        'function_name': context.function_name if context else 'unknown',
        'request_id': context.aws_request_id if context else 'unknown'
    })
