const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamoDB = new AWS.DynamoDB.DocumentClient();

const BUSINESS_ID = '723a276a-ad62-482c-898c-076d1f8d5c0e';
const TABLE_NAME = 'order-receiver-businesses-dev';

async function getBusinessItem() {
    console.log(`Fetching item with businessId: ${BUSINESS_ID} from table: ${TABLE_NAME}`);

    const params = {
        TableName: TABLE_NAME,
        Key: {
            'businessId': BUSINESS_ID
        }
    };

    try {
        const data = await dynamoDB.get(params).promise();
        if (data.Item) {
            console.log('✅ Found item:');
            console.log(JSON.stringify(data.Item, null, 2));
        } else {
            console.log(`❌ Item with businessId: ${BUSINESS_ID} not found.`);
        }
    } catch (error) {
        console.error('Error fetching item from DynamoDB:', error);
    }
}

getBusinessItem();
