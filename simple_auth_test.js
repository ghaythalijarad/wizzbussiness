console.log('🚀 Starting simple auth test...');

const https = require('https');

// Your login credentials
const EMAIL = 'g87_a@yahoo.com';
const PASSWORD = 'Gha@551987';

console.log(`📧 Testing login for: ${EMAIL}`);

const loginData = {
    email: EMAIL,
    password: PASSWORD,
    rememberMe: true
};

const options = {
    hostname: 'zz9cszv6a8.execute-api.us-east-1.amazonaws.com',
    port: 443,
    path: '/dev/auth/login',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
};

console.log('🔐 Sending login request...');

const req = https.request(options, (res) => {
    console.log(`📊 Response status: ${res.statusCode}`);
    
    let body = '';
    res.on('data', chunk => {
        body += chunk;
        console.log('📥 Receiving data...');
    });
    
    res.on('end', () => {
        console.log('📄 Full response received');
        console.log('Response body:', body);
        
        try {
            const parsed = JSON.parse(body);
            console.log('✅ Parsed response:', JSON.stringify(parsed, null, 2));
            
            if (parsed.success && parsed.tokens) {
                console.log('🎉 Login successful!');
                console.log(`👤 User ID: ${parsed.user?.userId}`);
                console.log(`🏢 Businesses: ${parsed.user?.businesses?.length || 0}`);
            } else {
                console.log('❌ Login failed:', parsed.message || 'Unknown error');
            }
        } catch (e) {
            console.log('❌ Failed to parse response:', e.message);
        }
    });
});

req.on('error', (error) => {
    console.error('❌ Request error:', error.message);
});

req.write(JSON.stringify(loginData));
req.end();

console.log('📤 Login request sent');
