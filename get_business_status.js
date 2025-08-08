
const { DynamoDBClient, GetItemCommand } = require("@aws-sdk/client-dynamodb");
const { marshall, unmarshall } = require("@aws-sdk/util-dynamodb");

const region = "us-east-1";
const tableName = "order-receiver-businesses-dev";

const client = new DynamoDBClient({ region });

async function getBusinessStatus(businessId) {
    if (!businessId) {
        console.error("Business ID is required.");
        process.exit(1);
    }

    console.log(`Checking status for business ID: ${businessId}`);

    const params = {
        TableName: tableName,
        Key: marshall({
            businessId: businessId,
        }),
    };

    try {
        const { Item } = await client.send(new GetItemCommand(params));

        if (Item) {
            const business = unmarshall(Item);
            console.log("Business data:", business);
            if (business.hasOwnProperty('acceptingOrders')) {
                console.log(`\n✅ Current 'acceptingOrders' status: ${business.acceptingOrders}`);
            } else {
                console.log("\n⚠️  'acceptingOrders' field does not exist for this business.");
            }
        } else {
            console.log("\n❌ Business not found.");
        }
    } catch (error) {
        console.error("Error getting business status:", error);
    }
}

const businessId = process.argv[2];
getBusinessStatus(businessId);
