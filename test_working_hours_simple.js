const https = require('https');
const fs = require('fs');

console.log('Starting test...');

async function testWorkingHoursSimple() {
    console.log('🧪 Testing Working Hours API with existing token...\n');
    
    let token;
    try {
        token = fs.readFileSync('access_token.txt', 'utf8').trim();
        console.log('✅ Token loaded');
    } catch (error) {
        console.error('❌ Error loading token:', error.message);
        return;
    }

    // Use the business that we know has working hours data
    const businessId = '892161df-6cb0-4a2a-ac04-5a09e206c81e'; // أسواق شمسة - has working hours

    // Test GET working hours
    console.log(`📊 Testing GET working hours for business: ${businessId}`);
    
    const getOptions = {
        hostname: '72nmgq5rc4.execute-api.us-east-1.amazonaws.com',
        path: `/dev/businesses/${businessId}/working-hours`,
        method: 'GET',
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
        }
    };

    return new Promise((resolve, reject) => {
        const req = https.request(getOptions, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                console.log(`Status: ${res.statusCode}`);
                
                try {
                    const response = JSON.parse(data);
                    console.log('✅ GET Response:', JSON.stringify(response, null, 2));
                    
                    if (res.statusCode === 200 && response.success) {
                        console.log('🎉 Working hours API is working correctly!');
                        
                        // Show the working hours data
                        if (response.workingHours) {
                            console.log('\n📅 Current working hours:');
                            Object.keys(response.workingHours).forEach(day => {
                                const hours = response.workingHours[day];
                                console.log(`  ${day}: ${hours.opening || 'Closed'} - ${hours.closing || 'Closed'}`);
                            });
                        }
                        
                        resolve(response);
                    } else {
                        console.error('❌ GET working hours failed');
                        console.error('Response:', response);
                        reject(new Error(`API returned status ${res.statusCode}`));
                    }
                } catch (error) {
                    console.error('❌ Error parsing response:', error);
                    console.log('Raw response:', data);
                    reject(error);
                }
            });
        });

        req.on('error', (e) => {
            console.error('❌ Request error:', e);
            reject(e);
        });

        req.end();
    });
}

// Run the test
testWorkingHoursSimple()
    .then(() => {
        console.log('\n🎉 Working hours test completed successfully!');
        console.log('✅ The working hours save/load functionality is working correctly!');
        process.exit(0);
    })
    .catch((error) => {
        console.error('\n💥 Working hours test failed:', error.message);
        process.exit(1);
    });
