const WebSocket = require('ws');

const WEBSOCKET_URL = 'wss://pyc140yn0h.execute-api.us-east-1.amazonaws.com/dev';
const BUSINESS_ID = 'test-business-123';

console.log('🔌 Testing WebSocket connection...');
console.log('URL:', WEBSOCKET_URL);

const wsUrl = `${WEBSOCKET_URL}?businessId=${BUSINESS_ID}&entityType=merchant&userId=${BUSINESS_ID}`;
console.log('Full URL:', wsUrl);

const ws = new WebSocket(wsUrl);

ws.on('open', function open() {
    console.log('✅ WebSocket connected successfully!');
    
    const message = {
        type: 'PING',
        businessId: BUSINESS_ID,
        timestamp: new Date().toISOString()
    };
    
    console.log('📤 Sending PING message...');
    ws.send(JSON.stringify(message));
    
    // Close after 3 seconds
    setTimeout(() => {
        console.log('🔌 Closing connection...');
        ws.close();
        process.exit(0);
    }, 3000);
});

ws.on('message', function message(data) {
    console.log('📥 Received:', data.toString());
});

ws.on('error', function error(err) {
    console.error('❌ WebSocket error:', err.message);
    process.exit(1);
});

ws.on('close', function close(code, reason) {
    console.log(`🔌 Connection closed. Code: ${code}, Reason: ${reason || 'No reason'}`);
    process.exit(0);
});

// Timeout after 10 seconds
setTimeout(() => {
    console.log('⏰ Test timeout - closing');
    ws.close();
    process.exit(1);
}, 10000);
