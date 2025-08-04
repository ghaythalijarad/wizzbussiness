const https = require('https');
const fs = require('fs');

async function testWorkingHoursAPI() {
  console.log('🕒 Testing Working Hours API...\n');
  
  const businessId = 'ef8366d7-e311-4a48-bf73-dcf1069cebe6';
  let token;
  
  try {
    token = fs.readFileSync('access_token.txt', 'utf8').trim();
    console.log('✅ Token loaded successfully');
  } catch (error) {
    console.error('❌ Error loading token:', error.message);
    return;
  }

  // Test GET working hours
  console.log(`\n📊 Testing GET working hours for business: ${businessId}`);
  
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
        console.log('Headers:', res.headers);
        
        try {
          const response = JSON.parse(data);
          console.log('Response:', JSON.stringify(response, null, 2));
          
          if (res.statusCode === 200 && response.success) {
            console.log('✅ GET working hours successful');
            
            // Test setting working hours
            testUpdateWorkingHours(businessId, token).then(resolve).catch(reject);
          } else {
            console.error('❌ GET working hours failed');
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

async function testUpdateWorkingHours(businessId, token) {
  console.log(`\n📝 Testing UPDATE working hours for business: ${businessId}`);
  
  const testWorkingHours = {
    Monday: { opening: '09:00', closing: '18:00' },
    Tuesday: { opening: '09:00', closing: '18:00' },
    Wednesday: { opening: '09:00', closing: '18:00' },
    Thursday: { opening: '09:00', closing: '18:00' },
    Friday: { opening: '09:00', closing: '18:00' },
    Saturday: { opening: '10:00', closing: '16:00' },
    Sunday: { opening: null, closing: null }
  };

  const updateOptions = {
    hostname: '72nmgq5rc4.execute-api.us-east-1.amazonaws.com',
    path: `/dev/businesses/${businessId}/working-hours`,
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(updateOptions, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        console.log(`Status: ${res.statusCode}`);
        
        try {
          const response = JSON.parse(data);
          console.log('Response:', JSON.stringify(response, null, 2));
          
          if (res.statusCode === 200 && response.success) {
            console.log('✅ UPDATE working hours successful');
            resolve();
          } else {
            console.error('❌ UPDATE working hours failed');
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

    req.write(JSON.stringify(testWorkingHours));
    req.end();
  });
}

// Run the test
testWorkingHoursAPI()
  .then(() => {
    console.log('\n🎉 All working hours API tests completed successfully!');
  })
  .catch((error) => {
    console.error('\n💥 Working hours API test failed:', error.message);
    process.exit(1);
  });
