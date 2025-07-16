const AWS = require('aws-sdk');
const axios = require('axios');

// AWS and environment configuration
const region = process.env.COGNITO_REGION || 'us-east-1';
const USER_POOL_ID = process.env.COGNITO_USER_POOL_ID;
const CLIENT_ID = process.env.COGNITO_CLIENT_ID;
const USERS_TABLE = process.env.USERS_TABLE;
const BUSINESSES_TABLE = process.env.BUSINESSES_TABLE;
const API_URL = process.env.API_URL || 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

AWS.config.update({ region });
const cognito = new AWS.CognitoIdentityServiceProvider();
const dynamodb = new AWS.DynamoDB.DocumentClient();

jest.setTimeout(30000);

describe('Auth Integration Tests', () => {
  let testEmail;
  let testPassword = 'Password123!';
  let registeredBusinessId;

  it('should return health status', async () => {
    const resp = await axios.get(`${API_URL}/auth/health`);
    expect(resp.status).toBe(200);
    expect(resp.data.success).toBe(true);
  });

  it('should check email availability before registration', async () => {
    testEmail = `test+${Date.now()}@example.com`;
    const resp = await axios.post(`${API_URL}/auth/check-email`, { email: testEmail });
    expect(resp.status).toBe(200);
    expect(resp.data.exists).toBe(false);
  });

  it('should register a new business user', async () => {
    const resp = await axios.post(
      `${API_URL}/auth/register-with-business`,
      { email: testEmail, password: testPassword, businessName: 'IntegrationTestBiz' },
      { headers: { 'Content-Type': 'application/json' } }
    );
    expect(resp.status).toBe(200);
    expect(resp.data.success).toBe(true);
    expect(resp.data.user_sub).toBeDefined();
    expect(resp.data.business_id).toBeDefined();
    registeredBusinessId = resp.data.business_id;
  });

  it('should check email availability after registration', async () => {
    const resp = await axios.post(`${API_URL}/auth/check-email`, { email: testEmail });
    expect(resp.status).toBe(200);
    expect(resp.data.exists).toBe(true);
  });

  afterAll(async () => {
    // Clean up Cognito user
    try {
      await cognito.adminDeleteUser({ UserPoolId: USER_POOL_ID, Username: testEmail }).promise();
    } catch (e) {
      console.warn('Failed to delete Cognito user:', e.message);
    }
    // Optionally clean up DynamoDB records (skipped)
  });
});
