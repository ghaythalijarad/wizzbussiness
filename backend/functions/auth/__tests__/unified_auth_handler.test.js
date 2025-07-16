const { handleRegisterWithBusiness, handleSignin } = require('../unified_auth_handler');
const { createResponse } = require('../utils');

// Mock AWS SDK components
jest.mock('aws-sdk', () => {
  const mCognito = {
    signUp: jest.fn().mockReturnValue({ promise: () => Promise.resolve({ UserSub: 'test-sub', CodeDeliveryDetails: {} }) }),
    initiateAuth: jest.fn().mockReturnValue({ promise: () => Promise.resolve({ AuthenticationResult: { AccessToken: 'token' } }) }),
    confirmSignUp: jest.fn().mockReturnValue({ promise: () => Promise.resolve() }),
    adminUpdateUserAttributes: jest.fn().mockReturnValue({ promise: () => Promise.resolve() }),
    adminGetUser: jest.fn().mockReturnValue({ promise: () => Promise.resolve() }),
    resendConfirmationCode: jest.fn().mockReturnValue({ promise: () => Promise.resolve({ CodeDeliveryDetails: {} }) })
  };
  const mDynamo = {
    put: jest.fn().mockReturnValue({ promise: () => Promise.resolve() }),
    query: jest.fn().mockReturnValue({ promise: () => Promise.resolve({ Items: [] }) }),
    update: jest.fn().mockReturnValue({ promise: () => Promise.resolve() })
  };
  return {
    CognitoIdentityServiceProvider: jest.fn(() => mCognito),
    DynamoDB: { DocumentClient: jest.fn(() => mDynamo) }
  };
});

describe('unified_auth_handler', () => {
  describe('handleRegisterWithBusiness', () => {
    it('should return 400 if required parameters are missing', async () => {
      const response = await handleRegisterWithBusiness({});
      expect(response.statusCode).toBe(400);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.message).toMatch(/Email, password, and business name are required/);
    });

    it('should succeed and return user_sub and business_id', async () => {
      const body = {
        email: 'user@example.com',
        password: 'Password123',
        businessName: 'My Business'
      };
      const response = await handleRegisterWithBusiness(body);
      expect(response.statusCode).toBe(200);
      const data = JSON.parse(response.body);
      expect(data.success).toBe(true);
      expect(data.user_sub).toBe('test-sub');
      expect(data.business_id).toBeDefined();
    });
  });

  describe('handleSignin', () => {
    it('should return 400 if email or password missing', async () => {
      const response = await handleSignin({});
      expect(response.statusCode).toBe(400);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.message).toMatch(/Email and password are required/);
    });

    it('should succeed and return authentication result', async () => {
      const body = { email: 'user@example.com', password: 'Password123' };
      const response = await handleSignin(body);
      expect(response.statusCode).toBe(200);
      const data = JSON.parse(response.body);
      expect(data.success).toBe(true);
      expect(data.data).toHaveProperty('AccessToken', 'token');
    });

    it('should return 401 for invalid credentials', async () => {
      // Override mock to throw error
      const AWS = require('aws-sdk');
      AWS.CognitoIdentityServiceProvider.mockImplementation(() => ({
        initiateAuth: () => ({ promise: () => Promise.reject({ code: 'NotAuthorizedException' }) })
      }));
      const response = await handleSignin({ email: 'foo', password: 'bar' });
      expect(response.statusCode).toBe(401);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.message).toMatch(/Invalid credentials/);
    });
  });
});
