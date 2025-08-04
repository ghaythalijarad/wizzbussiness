const WebSocket = require('ws');

async function testWebSocketConnection() {
    console.log('🧪 Testing WebSocket connection...');
    
    const wsUrl = 'wss://ujyixy3uh5.execute-api.us-east-1.amazonaws.com/dev';
    const testBusinessId = 'test-business-123';
    const fullUrl = `${wsUrl}?merchantId=${testBusinessId}`;
    
    console.log(`🔌 Connecting to: ${fullUrl}`);
    
    try {
        const ws = new WebSocket(fullUrl);
        
        ws.on('open', () => {
            console.log('✅ WebSocket connection opened successfully!');
            
            // Send a test message
            const testMessage = {
                type: 'SUBSCRIBE_ORDERS',
                businessId: testBusinessId,
                timestamp: new Date().toISOString()
            };
            
            console.log('📤 Sending test message:', testMessage);
            ws.send(JSON.stringify(testMessage));
        });
        
        ws.on('message', (data) => {
            const message = JSON.parse(data.toString());
            console.log('📨 Received message:', message);
            
            if (message.type === 'CONNECTION_ESTABLISHED') {
                console.log('🎉 WebSocket connection successfully established!');
                
                // Send a ping to test message handling
                setTimeout(() => {
                    const pingMessage = { type: 'PING', timestamp: new Date().toISOString() };
                    console.log('📤 Sending ping:', pingMessage);
                    ws.send(JSON.stringify(pingMessage));
                }, 1000);
            }
            
            if (message.type === 'PONG') {
                console.log('🏓 Ping/Pong test successful!');
                setTimeout(() => {
                    ws.close();
                }, 1000);
            }
        });
        
        ws.on('error', (error) => {
            console.error('❌ WebSocket error:', error);
        });
        
        ws.on('close', (code, reason) => {
            console.log(`🔌 WebSocket connection closed: ${code} - ${reason}`);
        });
        
        // Keep connection alive for testing
        setTimeout(() => {
            if (ws.readyState === WebSocket.OPEN) {
                console.log('⏰ Closing connection after timeout');
                ws.close();
            }
        }, 10000);
        
    } catch (error) {
        console.error('❌ Failed to create WebSocket connection:', error);
    }
}

if (require.main === module) {
    testWebSocketConnection().catch(console.error);
}

module.exports = { testWebSocketConnection };
