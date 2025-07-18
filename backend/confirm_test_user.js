const axios = require('axios');

// Configuration
const API_BASE_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

async function confirmTestUser(email, verificationCode) {
  console.log('✉️  Confirming Test User');
  console.log('=======================');
  console.log(`📧 Email: ${email}`);
  console.log(`🔢 Code: ${verificationCode}`);
  console.log('');

  try {
    const response = await axios.post(`${API_BASE_URL}/auth/confirm`, {
      email: email,
      verificationCode: verificationCode
    });
    
    console.log('✅ User confirmation successful:', response.data);
    return response.data;
  } catch (error) {
    console.error('❌ Confirmation failed:', error.response?.data || error.message);
    throw error;
  }
}

// If called directly
if (require.main === module) {
  const email = process.argv[2];
  const code = process.argv[3];
  
  if (!email || !code) {
    console.log('Usage: node confirm_test_user.js <email> <verification_code>');
    process.exit(1);
  }
  
  confirmTestUser(email, code);
}

module.exports = { confirmTestUser };
