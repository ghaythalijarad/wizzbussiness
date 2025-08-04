const AWS = require('aws-sdk');
const apiGatewayManagementApi = new AWS.ApiGatewayManagementApi({
  apiVersion: '2018-11-29',
  endpoint: process.env.WEBSOCKET_ENDPOINT.replace('wss://', ''),
});
const dynamoDb = new AWS.DynamoDB.DocumentClient();

// Use the same merchant endpoints table for WebSocket connections
const CONNECTIONS_TABLE = process.env.MERCHANT_ENDPOINTS_TABLE;

async function getConnectionsForBusiness(businessId) {
  const params = {
    TableName: CONNECTIONS_TABLE,
    KeyConditionExpression: 'merchantId = :merchantId AND endpointType = :type',
    ExpressionAttributeValues: {
      ':merchantId': businessId,
      ':type': 'websocket',
    },
  };

  try {
    const data = await dynamoDb.query(params).promise();
    return data.Items;
  } catch (error) {
    console.error('Error fetching connections for business:', error);
    return [];
  }
}

async function sendMessageToConnection(connectionId, message) {
  try {
    await apiGatewayManagementApi.postToConnection({
      ConnectionId: connectionId,
      Data: JSON.stringify(message),
    }).promise();
  } catch (error) {
    if (error.statusCode === 410) {
      console.log(`Found stale connection, deleting ${connectionId}`);
      await dynamoDb.delete({
        TableName: CONNECTIONS_TABLE,
        Key: { connectionId },
      }).promise();
    } else {
      console.error('Error sending message to connection:', error);
    }
  }
}

exports.handler = async (event) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  for (const record of event.Records) {
    if (record.eventName === 'INSERT') {
      const newOrder = AWS.DynamoDB.Converter.unmarshall(record.dynamodb.NewImage);
      
      // Real orders from customer app use 'storeId', test orders use 'businessId'
      const businessId = newOrder.storeId || newOrder.businessId;

      if (!businessId) {
        console.log('Order does not have a businessId or storeId, skipping notification.');
        console.log('Available fields:', Object.keys(newOrder));
        continue;
      }

      console.log(`Processing new order ${newOrder.orderId} for business ${businessId}`);

      const connections = await getConnectionsForBusiness(businessId);
      if (connections.length === 0) {
        console.log(`No active connections found for business ${businessId}.`);
        continue;
      }

      // Send the new order data under the "data" key so front-end can parse it
      const notification = {
        type: 'NEW_ORDER',
        data: newOrder,
      };

      const promises = connections.map(connection =>
        sendMessageToConnection(connection.connectionId, notification)
      );

      await Promise.all(promises);
    }
  }

  return {
    statusCode: 200,
    body: JSON.stringify({ message: 'Stream processed successfully.' }),
  };
};
