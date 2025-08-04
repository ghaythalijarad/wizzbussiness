const https = require('https');

// Test working hours update to reproduce the null values issue
async function testWorkingHoursUpdate() {
    const businessId = '892161df-6cb0-4a2a-ac04-5a09e206c81e';

    // Simulate what the frontend sends - mix of set and unset times
    const workingHoursData = {
        Monday: { opening: '09:00', closing: '17:00' },
        Tuesday: { opening: '09:00', closing: '17:00' },
        Wednesday: { opening: '09:00', closing: '17:00' },
        Thursday: { opening: '09:00', closing: '17:00' },
        Friday: { opening: null, closing: null }, // This should cause null values
        Saturday: { opening: '10:00', closing: '14:00' },
        Sunday: { opening: null, closing: null }
    };

    console.log('🧪 Testing working hours update with data:', JSON.stringify(workingHoursData, null, 2));

    const postData = JSON.stringify(workingHoursData);

    const options = {
        hostname: '72nmgq5rc4.execute-api.us-east-1.amazonaws.com',
        path: `/dev/businesses/${businessId}/working-hours`,
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer test-token', // We'll need a real token
            'Content-Length': Buffer.byteLength(postData)
        }
    };

    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                console.log(`✅ Response status: ${res.statusCode}`);
                console.log(`📝 Response body: ${data}`);
                resolve({ statusCode: res.statusCode, body: data });
            });
        });

        req.on('error', (error) => {
            console.error('❌ Request error:', error);
            reject(error);
        });

        req.write(postData);
        req.end();
    });
}

// For now, let's just test the data structure
console.log('🧪 Test data structure that would be sent:');
const testData = {
    Monday: { opening: '09:00', closing: '17:00' },
    Tuesday: { opening: '09:00', closing: '17:00' },
    Wednesday: { opening: '09:00', closing: '17:00' },
    Thursday: { opening: '09:00', closing: '17:00' },
    Friday: { opening: null, closing: null }, // Explicitly null - this is the issue
    Saturday: { opening: '10:00', closing: '14:00' },
    Sunday: { opening: null, closing: null }
};

console.log(JSON.stringify(testData, null, 2));

// Test the backend logic
console.log('\n🔍 Testing backend logic:');
Object.keys(testData).forEach(day => {
    const hours = testData[day] || {};
    console.log(`${day}:`);
    console.log(`  Original: opening=${hours.opening}, closing=${hours.closing}`);
    console.log(`  With ||: opening=${hours.opening || null}, closing=${hours.closing || null}`);
    console.log(`  With !== undefined: opening=${hours.opening !== undefined ? hours.opening : null}, closing=${hours.closing !== undefined ? hours.closing : null}`);
});
