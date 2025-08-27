const WebSocket = require('ws');

console.log('🔌 Testing direct WebSocket connection...');
console.log('📅 Current time:', new Date().toISOString());

const WEBSOCKET_URL = 'wss://pyc140yn0h.execute-api.us-east-1.amazonaws.com/dev';
const TEST_BUSINESS_ID = 'business_test_' + Date.now();

// Test WebSocket connection with business parameters
const wsUrl = `${WEBSOCKET_URL}?businessId=${TEST_BUSINESS_ID}&entityType=merchant&userId=${TEST_BUSINESS_ID}`;

console.log('🌐 Connecting to:', wsUrl);

const ws = new WebSocket(wsUrl);

let connectionEstablished = false;

const timeout = setTimeout(() => {
    if (!connectionEstablished) {
        console.log('⏰ Connection timeout (10 seconds)');
        process.exit(1);
    }
}, 10000);

ws.on('open', function open() {
    connectionEstablished = true;
    console.log('✅ WebSocket connection established!');
    
    // Send a test message
    const message = {
        type: 'PING',
        businessId: TEST_BUSINESS_ID,
        timestamp: new Date().toISOString(),
        source: 'direct_test'
    };
    
    console.log('📤 Sending test message:', JSON.stringify(message, null, 2));
    ws.send(JSON.stringify(message));
    
    // Close after 3 seconds
    setTimeout(() => {
        console.log('🔌 Closing connection...');
        ws.close();
    }, 3000);
});

ws.on('message', function message(data) {
    console.log('📥 Received message:', data.toString());
});

ws.on('error', function error(err) {
    console.error('❌ WebSocket error:', err.message);
    clearTimeout(timeout);
    process.exit(1);
});

ws.on('close', function close(code, reason) {
    console.log(`🔌 Connection closed. Code: ${code}, Reason: ${reason || 'None'}`);
    clearTimeout(timeout);
    
    if (connectionEstablished) {
        console.log('✅ WebSocket test completed successfully!');
        process.exit(0);
    } else {
        console.log('❌ WebSocket test failed');
        process.exit(1);
    }
});
