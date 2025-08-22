const AWS = require('aws-sdk');
const apiGatewayManagementApi = new AWS.ApiGatewayManagementApi({
  apiVersion: '2018-11-29',
  endpoint: process.env.WEBSOCKET_ENDPOINT.replace('wss://', ''),
});
const dynamoDb = new AWS.DynamoDB.DocumentClient();

// Unified websocket connections table & GSI
const CONNECTIONS_TABLE = process.env.WEBSOCKET_CONNECTIONS_TABLE; // unified only
const GSI_NAME = 'GSI1';

async function getConnectionsForBusiness(businessId) {
  // Query GSI (BUSINESS#<id>) only – legacy fallback removed post-migration
  const gsiParams = {
    TableName: CONNECTIONS_TABLE,
    IndexName: GSI_NAME,
    KeyConditionExpression: 'GSI1PK = :pk',
    ExpressionAttributeValues: {
      ':pk': `BUSINESS#${businessId}`,
    },
    FilterExpression: 'attribute_not_exists(isStale)'
  };
  try {
    const data = await dynamoDb.query(gsiParams).promise();
    return (data.Items || []).map(i => ({ connectionId: i.connectionId, pk: i.PK, sk: i.SK }));
  } catch (err) {
    console.error('[order_stream_handler] GSI query failed (should not happen post-migration)', err.code || err.message);
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
      console.log(`[order_stream_handler] Stale connection detected ${connectionId}`);
      try {
        await dynamoDb.delete({
          TableName: CONNECTIONS_TABLE,
          Key: { PK: `CONNECTION#${connectionId}`, SK: `CONNECTION#${connectionId}` }
        }).promise();
      } catch (_) { }
    } else {
      console.error('[order_stream_handler] Error sending websocket message', { connectionId, error: error.message });
    }
  }
}

exports.handler = async (event) => {
  console.log('[order_stream_handler] Received event batch size', event.Records?.length || 0);

  for (const record of event.Records) {
    if (record.eventName === 'INSERT') {
      const newOrder = AWS.DynamoDB.Converter.unmarshall(record.dynamodb.NewImage);
      const businessId = newOrder.storeId || newOrder.businessId;
      if (!businessId) {
        console.log('[order_stream_handler] Order missing businessId/storeId; skipping', { orderId: newOrder.orderId });
        continue;
      }

      console.log(`[order_stream_handler] New order ${newOrder.orderId} for business ${businessId}`);
      const connections = await getConnectionsForBusiness(businessId);
      if (!connections.length) {
        console.log(`[order_stream_handler] No active websocket connections for business ${businessId}`);
        continue;
      }

      const notification = {
        type: 'NEW_ORDER',
        payload: {
          aps: {
            alert: {
              title: 'New Order Received',
              subtitle: `Order ID: ${newOrder.orderId}`,
              body: `You have a new order for $${newOrder.totalAmount || 'N/A'}. Please review and respond.`,
            },
            category: 'NEW_ORDER_CATEGORY',
            'mutable-content': 1,
          },
          data: {
            ...newOrder,
            orderId: newOrder.orderId,
            businessId,
            actions: [
              { id: 'ACCEPT_ORDER', title: 'Accept' },
              { id: 'REJECT_ORDER', title: 'Reject' },
            ]
          }
        }
      };

      await Promise.all(connections.map(c => sendMessageToConnection(c.connectionId, notification)));
      console.log(`[order_stream_handler] Delivered NEW_ORDER to ${connections.length} connection(s)`);
    }
  }

  return { statusCode: 200, body: JSON.stringify({ message: 'Stream processed successfully.' }) };
};
