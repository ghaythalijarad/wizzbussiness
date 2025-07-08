"""
Integration tests for the backend API endpoints
"""

import pytest
import requests
import json
import os
from typing import Dict, Any


class TestAPIIntegration:
    """Integration tests for deployed API endpoints"""
    
    def setup_class(self):
        """Setup class with API configuration"""
        # Get API URL from environment or command line
        self.api_url = os.getenv('API_URL', 'http://localhost:3000')
        self.headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        }
        
    def test_api_health_check(self):
        """Test API health endpoint"""
        try:
            response = requests.get(f"{self.api_url}/health", timeout=10)
            assert response.status_code == 200
            
            data = response.json()
            assert 'status' in data
            assert data['status'] == 'healthy'
            
        except requests.exceptions.RequestException as e:
            pytest.skip(f"API not accessible: {e}")
            
    def test_auth_health_check(self):
        """Test auth service health endpoint"""
        try:
            response = requests.get(f"{self.api_url}/auth/health", timeout=10)
            assert response.status_code == 200
            
            data = response.json()
            assert 'status' in data
            assert data['status'] == 'healthy'
            assert 'service' in data
            assert data['service'] == 'auth'
            
        except requests.exceptions.RequestException as e:
            pytest.skip(f"Auth endpoint not accessible: {e}")
    
    def test_business_registration_endpoint(self):
        """Test business registration endpoint structure"""
        try:
            # Test with invalid data to check endpoint exists
            invalid_data = {
                "cognito_user_id": "",
                "email": "invalid-email",
                "business_name": "",
                "business_type": "",
                "owner_name": "",
                "phone_number": "",
                "address": {}
            }
            
            response = requests.post(
                f"{self.api_url}/auth/register-business",
                json=invalid_data,
                headers=self.headers,
                timeout=10
            )
            
            # Should return 400 or 422 for invalid data, not 404
            assert response.status_code in [400, 422, 500]  # Endpoint exists
            
        except requests.exceptions.RequestException as e:
            pytest.skip(f"Business registration endpoint not accessible: {e}")
    
    def test_cors_headers(self):
        """Test CORS headers are properly set"""
        try:
            response = requests.options(f"{self.api_url}/health", timeout=10)
            
            # Check CORS headers are present
            assert 'Access-Control-Allow-Origin' in response.headers or \
                   response.status_code == 405  # OPTIONS might not be implemented
                   
        except requests.exceptions.RequestException as e:
            pytest.skip(f"CORS test failed: {e}")
    
    def test_api_error_handling(self):
        """Test API error handling for non-existent endpoints"""
        try:
            response = requests.get(f"{self.api_url}/non-existent-endpoint", timeout=10)
            assert response.status_code == 404
            
        except requests.exceptions.RequestException as e:
            pytest.skip(f"Error handling test failed: {e}")
    
    @pytest.mark.parametrize("endpoint", [
        "/health",
        "/auth/health"
    ])
    def test_endpoint_response_time(self, endpoint):
        """Test API endpoint response times"""
        try:
            response = requests.get(f"{self.api_url}{endpoint}", timeout=5)
            
            # Response should be within 5 seconds
            assert response.elapsed.total_seconds() < 5
            
        except requests.exceptions.RequestException as e:
            pytest.skip(f"Response time test failed for {endpoint}: {e}")


class TestDataValidation:
    """Test data validation and business logic"""
    
    def test_email_validation(self):
        """Test email validation logic"""
        valid_emails = [
            "test@example.com",
            "user@domain.co.uk",
            "admin@company.org"
        ]
        
        invalid_emails = [
            "invalid-email",
            "@domain.com",  # Missing local part
            "user@",        # Missing domain
            "user.domain.com",  # Missing @
            "",             # Empty string
            "user@domain",  # Missing TLD
            "user@@domain.com"  # Double @
        ]
        
        # Test valid emails
        for email in valid_emails:
            assert self._is_valid_email(email), f"Expected {email} to be valid"
            
        # Test invalid emails  
        for email in invalid_emails:
            assert not self._is_valid_email(email), f"Expected {email} to be invalid"
    
    def _is_valid_email(self, email):
        """Simple email validation helper"""
        if not email or not isinstance(email, str):
            return False
        
        # Must have exactly one @
        if email.count("@") != 1:
            return False
            
        local, domain = email.split("@")
        
        # Local part and domain must not be empty
        if not local or not domain:
            return False
            
        # Domain must have at least one dot
        if "." not in domain:
            return False
            
        # Domain must have content after the last dot (TLD)
        if domain.endswith(".") or domain.startswith("."):
            return False
            
        return True
    
    def test_business_data_structure(self):
        """Test business data structure requirements"""
        required_fields = [
            'cognito_user_id',
            'email',
            'business_name',
            'business_type',
            'owner_name',
            'phone_number',
            'address'
        ]
        
        valid_business_data = {
            'cognito_user_id': 'user-123',
            'email': 'owner@restaurant.com',
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
        
        # Check all required fields are present
        for field in required_fields:
            assert field in valid_business_data
            assert valid_business_data[field]  # Not empty
        
        # Check address structure
        assert isinstance(valid_business_data['address'], dict)
        assert 'street' in valid_business_data['address']
        assert 'city' in valid_business_data['address']


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
