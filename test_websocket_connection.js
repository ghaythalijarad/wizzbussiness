const WebSocket = require('ws');

async function testWebSocketConnection() {
    console.log('🔍 Testing WebSocket connection status...\n');

    const connectionId = 'O9hYEdIfIAMCLDg=';
    const wsEndpoint = 'wss://yafz9z7pck.execute-api.us-east-1.amazonaws.com/dev';

    console.log(`Testing connection to: ${wsEndpoint}`);
    console.log(`Connection ID to test: ${connectionId}\n`);

    try {
      const ws = new WebSocket(wsEndpoint);

      ws.on('open', function open() {
          console.log('✅ WebSocket connection opened');

          // Send a test message
          const testMessage = {
            action: 'ping',
            connectionId: connectionId
        };

        ws.send(JSON.stringify(testMessage));
        console.log('📤 Sent test message:', JSON.stringify(testMessage));
    });

      ws.on('message', function message(data) {
          console.log('📥 Received message:', data.toString());
          ws.close();
    });

      ws.on('close', function close() {
          console.log('🔴 WebSocket connection closed');
      });

      ws.on('error', function error(err) {
          console.error('❌ WebSocket error:', err);
      });

      // Close connection after 10 seconds
      setTimeout(() => {
          if (ws.readyState === WebSocket.OPEN) {
              console.log('⏰ Closing connection after timeout');
              ws.close();
          }
      }, 10000);

  } catch (error) {
      console.error('❌ Error testing WebSocket:', error);
  }
}

// Test the connection
testWebSocketConnection();
