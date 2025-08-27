const WebSocket = require('ws');

console.log('🚀 Starting Simple WebSocket Test...');
console.log('WebSocket library loaded:', typeof WebSocket);

const WEBSOCKET_URL = 'wss://pyc140yn0h.execute-api.us-east-1.amazonaws.com/dev';
const BUSINESS_ID = 'business_1756220656049_ee98qktepks';

const wsUrl = `${WEBSOCKET_URL}?businessId=${BUSINESS_ID}&entityType=merchant&userId=${BUSINESS_ID}`;

console.log('🔗 Connecting to:', wsUrl);

try {
    const ws = new WebSocket(wsUrl);
    console.log('WebSocket instance created');

    ws.on('open', function() {
        console.log('✅ WebSocket connection established!');
        
        // Send a simple ping
        const message = {
            type: 'PING',
            businessId: BUSINESS_ID,
            timestamp: new Date().toISOString()
        };
        
        console.log('📤 Sending ping...');
        ws.send(JSON.stringify(message));
        
        // Close after 3 seconds
        setTimeout(() => {
            console.log('🔌 Closing connection...');
            ws.close();
        }, 3000);
    });

    ws.on('message', function(data) {
        console.log('📥 Received:', data.toString());
    });

    ws.on('error', function(error) {
        console.error('❌ WebSocket error:', error.message);
        console.error('Error details:', error);
        process.exit(1);
    });

    ws.on('close', function(code, reason) {
        console.log(`🔌 Connection closed. Code: ${code}, Reason: ${reason || 'No reason'}`);
        process.exit(0);
    });

    // Timeout after 10 seconds
    setTimeout(() => {
        console.log('⏰ Test timeout');
        ws.close();
        process.exit(1);
    }, 10000);

    console.log('Event listeners attached, waiting for connection...');

} catch (error) {
    console.error('Failed to create WebSocket:', error);
    process.exit(1);
}
