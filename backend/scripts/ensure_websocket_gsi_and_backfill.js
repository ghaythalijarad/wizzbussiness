#!/usr/bin/env node
/**
 * ensure_websocket_gsi_and_backfill.js
 *
 * Adds (if missing) GSI1 (HASH: GSI1PK, RANGE: GSI1SK) to the unified websocket connections table
 * then backfills existing items so server code relying on PK/SK + GSI1 works efficiently.
 *
 * Table (expected final schema):
 *   PK: CONNECTION#<connectionId>
 *   SK: CONNECTION#<connectionId>
 *   GSI1PK: BUSINESS#<businessId> | USER#<userId>
 *   GSI1SK: CONNECTION#<connectionId>
 *   connectionId, businessId, userId, entityType, connectedAt (ISO), ttl (epoch seconds)
 *
 * Usage:
 *   node backend/scripts/ensure_websocket_gsi_and_backfill.js \
 *     --table WhizzMerchants_WebsocketConnections [--region us-east-1] [--ttlHours 1]
 *
 * Safe to re-run (idempotent). Will only create missing index / attributes.
 */
const { DynamoDBClient, DescribeTableCommand, UpdateTableCommand } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, UpdateCommand, PutCommand, DeleteCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');

const argv = yargs(hideBin(process.argv))
    .option('table', { type: 'string', demandOption: true })
    .option('region', { type: 'string', default: process.env.AWS_REGION || 'us-east-1' })
    .option('ttlHours', { type: 'number', default: 1 })
    .help()
    .argv;

const TABLE = argv.table;
const REGION = argv.region;
const TTL_HOURS = argv.ttlHours;

const low = new DynamoDBClient({ region: REGION });
const ddb = DynamoDBDocumentClient.from(low);

async function describeTable() {
    const res = await low.send(new DescribeTableCommand({ TableName: TABLE }));
    return res.Table;
}

function hasGSI1(table) {
    return (table.GlobalSecondaryIndexes || []).some(g => g.IndexName === 'GSI1');
}

async function ensureGSI() {
    const table = await describeTable();
    if (hasGSI1(table)) {
        console.log('ℹ️  GSI1 already present');
        return;
    }
    console.log('🚀 Creating GSI1 (GSI1PK, GSI1SK)...');
    await low.send(new UpdateTableCommand({
        TableName: TABLE,
        AttributeDefinitions: [
            { AttributeName: 'GSI1PK', AttributeType: 'S' },
            { AttributeName: 'GSI1SK', AttributeType: 'S' }
        ],
        GlobalSecondaryIndexUpdates: [
            {
                Create: {
                    IndexName: 'GSI1',
                    KeySchema: [
                        { AttributeName: 'GSI1PK', KeyType: 'HASH' },
                        { AttributeName: 'GSI1SK', KeyType: 'RANGE' }
                    ],
                    Projection: { ProjectionType: 'ALL' }
                }
            }
        ]
    }));
    // Wait until ACTIVE
    while (true) {
        await new Promise(r => setTimeout(r, 5000));
        const t = await describeTable();
        const g = t.GlobalSecondaryIndexes.find(i => i.IndexName === 'GSI1');
        const status = g?.IndexStatus;
        console.log('⏳ Waiting for GSI1 ACTIVE... current:', status);
        if (status === 'ACTIVE') break;
    }
    console.log('✅ GSI1 ACTIVE');
}

function computeTTL(connectedAtIso) {
    const base = connectedAtIso ? Date.parse(connectedAtIso) : Date.now();
    const ttlMs = TTL_HOURS * 3600 * 1000;
    return Math.floor((base + ttlMs) / 1000);
}

async function backfill() {
    console.log('🔍 Scanning table for backfill...');

    // First, determine the actual primary key of the table
    const tableInfo = await describeTable();
    const keySchema = tableInfo.KeySchema;
    const pkField = keySchema.find(k => k.KeyType === 'HASH').AttributeName;
    const skField = keySchema.find(k => k.KeyType === 'RANGE')?.AttributeName;
    console.log(`ℹ️  Table primary key is HASH: "${pkField}"` + (skField ? `, RANGE: "${skField}"` : ''));


    let ExclusiveStartKey = undefined;
    let total = 0, updated = 0, skipped = 0, recreated = 0;

    do {
        const scanRes = await ddb.send(new ScanCommand({ TableName: TABLE, ExclusiveStartKey }));
        for (const item of scanRes.Items || []) {
            total++;

            // If GSI1PK is present, assume it's correctly backfilled.
            if (item.GSI1PK) {
                skipped++;
                continue;
            }

            // This is the crucial part. If the item is legacy, it won't have the NEW PK/SK schema.
            // We must delete it using its OLD, actual primary key.
            if (item.PK !== `CONNECTION#${item.connectionId}`) {
                console.log(`♻️  Re-creating legacy item for connectionId: ${item.connectionId || item.id}`);

                const connectionId = item.connectionId || item.id;
                if (!connectionId) {
                    console.warn('⚠️  Item missing connectionId/id, cannot process. Skipping.', item);
                    skipped++;
                    continue;
                }

                // Construct the key to delete the old item using the *actual* table key schema
                const legacyKey = {
                    [pkField]: item[pkField]
                };
                if (skField) {
                    legacyKey[skField] = item[skField];
                }


                const businessId = item.businessId || item.merchantId;
                const userId = item.userId || businessId || 'guest';
                const entityType = businessId ? 'merchant' : 'user';
                const connectedAt = item.connectedAt || new Date().toISOString();
                const ttl = item.ttl && item.ttl > Math.floor(Date.now() / 1000) ? item.ttl : computeTTL(item.connectedAt);

                const newItem = {
                    PK: `CONNECTION#${connectionId}`,
                    SK: `CONNECTION#${connectionId}`,
                    GSI1PK: businessId ? `BUSINESS#${businessId}` : `USER#${userId}`,
                    GSI1SK: `CONNECTION#${connectionId}`,
                    connectionId,
                    entityType,
                    connectedAt,
                    ttl,
                };
                // Add optional attributes only if they exist on the original item
                if (businessId) newItem.businessId = businessId;
                if (item.userId) newItem.userId = item.userId;


                try {
                    // Delete the old item, then put the new, corrected item.
                    await ddb.send(new DeleteCommand({ TableName: TABLE, Key: legacyKey }));
                    await ddb.send(new PutCommand({ TableName: TABLE, Item: newItem }));
                    recreated++;
                } catch (e) {
                    console.error(`❌ Failed to recreate item with legacy key ${JSON.stringify(legacyKey)}. Error: ${e.message}`);
                    console.error('Original item:', item);
                    // Best effort to put the original item back if something went wrong.
                    await ddb.send(new PutCommand({ TableName: TABLE, Item: item }));
                    skipped++;
                }

            } else {
                // Item has the correct PK/SK, so we can just update it with GSI attributes.
                // This path is for items created after the schema change but before the backfill.
                const businessId = item.businessId || item.merchantId;
                const userId = item.userId || businessId || 'guest';

                await ddb.send(new UpdateCommand({
                    TableName: TABLE,
                    Key: { PK: item.PK, SK: item.SK },
                    UpdateExpression: 'SET #gsi1pk = :gsi1pk, #gsi1sk = :gsi1sk',
                    ExpressionAttributeNames: {
                        '#gsi1pk': 'GSI1PK',
                        '#gsi1sk': 'GSI1SK',
                    },
                    ExpressionAttributeValues: {
                        ':gsi1pk': businessId ? `BUSINESS#${businessId}` : `USER#${userId}`,
                        ':gsi1sk': `CONNECTION#${item.connectionId}`,
                    }
                }));
                updated++;
            }
        }
        ExclusiveStartKey = scanRes.LastEvaluatedKey;
    } while (ExclusiveStartKey);
    console.log(`📊 Backfill complete. Total scanned: ${total}, updated: ${updated}, recreated: ${recreated}, skipped: ${skipped}`);
}

async function verifySample(limit = 5) {
    console.log('🔎 Verifying sample items via GSI1...');
    const res = await ddb.send(new QueryCommand({
        TableName: TABLE,
        IndexName: 'GSI1',
        KeyConditionExpression: 'GSI1PK = :pk',
        ExpressionAttributeValues: { ':pk': 'BUSINESS#TEST_NON_EXISTENT' },
        Limit: 1
    }));
    console.log('GSI1 query path operational (empty expected):', res.Count === 0 ? '✅' : 'Check');
}

(async () => {
    console.log(`➡️  Ensuring GSI + backfill for table ${TABLE} (region ${REGION})`);
    await ensureGSI().catch(e => { console.error('Failed creating GSI1:', e.message); process.exit(1); });
    await backfill().catch(e => { console.error('Backfill failed:', e.message); process.exit(1); });
    await verifySample();
    console.log('🎉 Migration step complete');
})();
