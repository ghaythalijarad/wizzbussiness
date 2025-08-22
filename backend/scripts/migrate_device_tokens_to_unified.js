#!/usr/bin/env node
/**
 * migrate_device_tokens_to_unified.js
 *
 * Migrates device tokens from MERCHANT_ENDPOINTS_TABLE to unified WEBSOCKET_CONNECTIONS_TABLE
 * with DEVICE# PK/SK pattern and BUSINESS# GSI1PK for efficient querying.
 *
 * Prerequisites:
 * 1. GSI1 must exist on WEBSOCKET_CONNECTIONS_TABLE (run ensure_websocket_gsi_and_backfill.js first)
 * 2. Updated Lambda handlers must be deployed
 *
 * Usage:
 *   node migrate_device_tokens_to_unified.js \
 *     --sourceTable WhizzMerchants_MerchantEndpoints \
 *     --targetTable wizzgo-dev-wss-onconnect \
 *     [--region us-east-1] [--dryRun] [--ttlDays 30]
 *
 * Safe to re-run (checks for existing DEVICE# items).
 */
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, PutCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');

const argv = yargs(hideBin(process.argv))
    .option('sourceTable', { type: 'string', demandOption: true, describe: 'Legacy MERCHANT_ENDPOINTS_TABLE name' })
    .option('targetTable', { type: 'string', demandOption: true, describe: 'Unified WEBSOCKET_CONNECTIONS_TABLE name' })
    .option('region', { type: 'string', default: process.env.AWS_REGION || 'us-east-1' })
    .option('dryRun', { type: 'boolean', default: false, describe: 'Preview changes without writing' })
    .option('ttlDays', { type: 'number', default: 30, describe: 'TTL for device tokens in days' })
    .help()
    .argv;

const SOURCE_TABLE = argv.sourceTable;
const TARGET_TABLE = argv.targetTable;
const REGION = argv.region;
const DRY_RUN = argv.dryRun;
const TTL_DAYS = argv.ttlDays;

const low = new DynamoDBClient({ region: REGION });
const ddb = DynamoDBDocumentClient.from(low);

function computeTTL() {
    return Math.floor(Date.now() / 1000) + (TTL_DAYS * 24 * 60 * 60);
}

async function checkExistingDeviceToken(deviceToken) {
    try {
        const res = await ddb.send(new QueryCommand({
            TableName: TARGET_TABLE,
            KeyConditionExpression: 'PK = :pk',
            ExpressionAttributeValues: { ':pk': `DEVICE#${deviceToken}` },
            Limit: 1
        }));
        return res.Items && res.Items.length > 0;
    } catch (e) {
        return false;
    }
}

async function migrateMobileEndpoints() {
    console.log(`🔄 Migrating mobile push endpoints from ${SOURCE_TABLE} to ${TARGET_TABLE}`);
    console.log(`🌍 Region: ${REGION}, DryRun: ${DRY_RUN}, TTL: ${TTL_DAYS} days`);

    let ExclusiveStartKey = undefined;
    let total = 0, migrated = 0, skipped = 0, errors = 0;

    do {
        try {
            const scanRes = await ddb.send(new ScanCommand({
                TableName: SOURCE_TABLE,
                FilterExpression: 'endpointType = :type',
                ExpressionAttributeValues: { ':type': 'mobile_push' },
                ExclusiveStartKey
            }));

            for (const item of scanRes.Items || []) {
                total++;

                if (!item.deviceToken || !item.merchantId) {
                    console.warn(`⚠️  Skipping item missing deviceToken/merchantId:`, { merchantId: item.merchantId, endpointType: item.endpointType });
                    skipped++;
                    continue;
                }

                // Check if already migrated
                const exists = await checkExistingDeviceToken(item.deviceToken);
                if (exists) {
                    console.log(`✅ Device token already migrated: ${item.deviceToken.substring(0, 12)}...`);
                    skipped++;
                    continue;
                }

                const timestamp = new Date().toISOString();
                const unifiedItem = {
                    PK: `DEVICE#${item.deviceToken}`,
                    SK: `DEVICE#${item.deviceToken}`,
                    GSI1PK: `BUSINESS#${item.merchantId}`,
                    GSI1SK: `DEVICE#${item.deviceToken}`,
                    entityType: 'mobile_push',
                    endpointType: 'mobile_push', // legacy compatibility
                    merchantId: item.merchantId,
                    businessId: item.merchantId,
                    deviceToken: item.deviceToken,
                    platform: item.platform || 'unknown',
                    isActive: item.isActive !== false,
                    registeredAt: item.registeredAt || timestamp,
                    updatedAt: item.updatedAt || timestamp,
                    ttl: computeTTL(),
                    // Preserve any additional fields
                    ...(item.disabledAt && { disabledAt: item.disabledAt })
                };

                if (DRY_RUN) {
                    console.log(`🔍 [DRY-RUN] Would migrate:`, {
                        deviceToken: item.deviceToken.substring(0, 12) + '...',
                        merchantId: item.merchantId,
                        platform: item.platform,
                        isActive: item.isActive
                    });
                } else {
                    try {
                        await ddb.send(new PutCommand({
                            TableName: TARGET_TABLE,
                            Item: unifiedItem
                        }));
                        console.log(`✅ Migrated device token: ${item.deviceToken.substring(0, 12)}... for merchant ${item.merchantId}`);
                    } catch (putError) {
                        console.error(`❌ Failed to migrate token ${item.deviceToken.substring(0, 12)}...:`, putError.message);
                        errors++;
                        continue;
                    }
                }

                migrated++;
            }

            ExclusiveStartKey = scanRes.LastEvaluatedKey;
        } catch (scanError) {
            console.error('❌ Scan error:', scanError.message);
            break;
        }
    } while (ExclusiveStartKey);

    console.log(`📊 Migration summary:`);
    console.log(`   Total scanned: ${total}`);
    console.log(`   ${DRY_RUN ? 'Would migrate' : 'Migrated'}: ${migrated}`);
    console.log(`   Skipped (existing/invalid): ${skipped}`);
    if (errors > 0) console.log(`   Errors: ${errors}`);
}

async function verifyMigration() {
    if (DRY_RUN) return;

    console.log('🔍 Verifying migration with sample GSI1 query...');
    try {
        // Try to find any BUSINESS# items in GSI1
        const res = await ddb.send(new QueryCommand({
            TableName: TARGET_TABLE,
            IndexName: 'GSI1',
            KeyConditionExpression: 'begins_with(GSI1PK, :prefix)',
            ExpressionAttributeValues: { ':prefix': 'BUSINESS#' },
            FilterExpression: 'entityType = :type',
            ExpressionAttributeNames: { '#type': 'entityType' },
            ExpressionAttributeValues: { ':type': 'mobile_push' },
            Limit: 5
        }));

        console.log(`✅ Found ${res.Items?.length || 0} migrated device tokens via GSI1`);
        if (res.Items?.length > 0) {
            console.log('Sample migrated item:', {
                GSI1PK: res.Items[0].GSI1PK,
                entityType: res.Items[0].entityType,
                platform: res.Items[0].platform
            });
        }
    } catch (verifyError) {
        console.warn('⚠️  Verification query failed:', verifyError.message);
    }
}

(async () => {
    try {
        await migrateMobileEndpoints();
        await verifyMigration();
        console.log('🎉 Device token migration complete');

        if (!DRY_RUN) {
            console.log('\n📋 Next steps:');
            console.log('1. Deploy updated Lambda handlers (if not already done)');
            console.log('2. Test device token registration via API');
            console.log('3. Verify push notifications work via unified table');
            console.log('4. Remove MERCHANT_ENDPOINTS_TABLE references from serverless.yml');
            console.log('5. Consider deleting legacy table after validation period');
        }
    } catch (error) {
        console.error('❌ Migration failed:', error.message);
        process.exit(1);
    }
})();
