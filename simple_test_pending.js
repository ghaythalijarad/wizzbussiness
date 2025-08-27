#!/usr/bin/env node

console.log('🧪 TESTING PENDING ACCOUNT FLOW');
console.log('================================');

const email = 'g87_a@yahoo.com';
const password = 'Gha@551987';

// Simple fetch test
async function testLogin() {
  try {
    console.log('📋 Testing API Login Endpoint...');
    
    const response = await fetch('https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/signin', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: email,
        password: password
      })
    });

    console.log('📊 Response Status:', response.status);
    const data = await response.json();
    console.log('📊 Response Data:', JSON.stringify(data, null, 2));

    if (data.success && data.businesses && data.businesses.length > 0) {
      const business = data.businesses[0];
      console.log('\n🎯 KEY FINDINGS:');
      console.log(`   Business ID: ${business.businessId}`);
      console.log(`   Business Status: "${business.status}"`);
      console.log(`   Expected Route: ${business.status === 'approved' ? 'BusinessDashboard' : 'MerchantStatusScreen'}`);
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

testLogin();
