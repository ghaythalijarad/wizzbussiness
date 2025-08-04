
const https = require('https');
const fs = require('fs');

const idToken = fs.readFileSync('/Users/ghaythallaheebi/order-receiver-app-2/id_token.txt', 'utf-8').trim();

const options = {
  hostname: '72nmgq5rc4.execute-api.us-east-1.amazonaws.com',
  path: '/dev/orders',
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${idToken}`,
    'Content-Type': 'application/json'
  }
};

const data = JSON.stringify({
  item: 'My new shiny toy',
  quantity: 1
});

const req = https.request(options, (res) => {
  console.log(`statusCode: ${res.statusCode}`);

  let body = '';
  res.on('data', (chunk) => {
    body += chunk;
  });

  res.on('end', () => {
    console.log('Response body:', body);
  });
});

req.on('error', (error) => {
  console.error('Request error:', error);
});

req.write(data);
req.end();
