const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, QueryCommand, DeleteCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');

const dynamoDbClient = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);

/**
 * Simplified WebSocket Service for Auth Function
 * Contains only the logout cleanup functionality needed by the auth handler
 */

const TABLE_NAME = 'WizzUser_websocket_connections_dev';

/**
 * Remove business connections from WebSocket table
 */
async function removeBusinessConnections(businessId, userId, options = {}) {
    try {
        const {
            connectionType = null, // null means remove all types
            source = 'logout',
            dryRun = false
        } = options;

        console.log(`🧹 Removing business connections - Business: ${businessId}, User: ${userId}`);
        console.log(`   Connection type filter: ${connectionType || 'ALL'}`);
        console.log(`   Source: ${source}`);
        console.log(`   Dry run: ${dryRun}`);

        // Query for connections by businessId (assuming userId is used as businessId in the GSI)
        const queryParams = {
            TableName: TABLE_NAME,
            IndexName: 'userId-connectedAt-index',
            KeyConditionExpression: 'userId = :businessId',
            ExpressionAttributeValues: {
                ':businessId': businessId
            }
        };

        const queryResult = await dynamodb.send(new QueryCommand(queryParams));
        const connections = queryResult.Items || [];

        console.log(`   Found ${connections.length} connections to evaluate`);

        // Filter by connection type if specified
        const connectionsToRemove = connectionType 
            ? connections.filter(conn => conn.connectionType === connectionType)
            : connections;

        console.log(`   ${connectionsToRemove.length} connections match removal criteria`);

        if (dryRun) {
            console.log('   🔍 DRY RUN - Would remove connections:', connectionsToRemove.map(c => ({
                connectionId: c.connectionId,
                type: c.connectionType,
                connectedAt: c.connectedAt
            })));
            return {
                success: true,
                connectionsFound: connections.length,
                connectionsToRemove: connectionsToRemove.length,
                removedConnections: 0,
                dryRun: true
            };
        }

        // Remove connections
        const deletePromises = connectionsToRemove.map(async (connection) => {
            try {
                const deleteParams = {
                    TableName: TABLE_NAME,
                    Key: {
                        PK: connection.PK,
                        SK: connection.SK
                    }
                };

                await dynamodb.send(new DeleteCommand(deleteParams));
                console.log(`   ✅ Removed connection: ${connection.connectionId}`);
                return { success: true, connectionId: connection.connectionId };
            } catch (error) {
                console.error(`   ❌ Failed to remove connection ${connection.connectionId}:`, error.message);
                return { success: false, connectionId: connection.connectionId, error: error.message };
            }
        });

        const deleteResults = await Promise.all(deletePromises);
        const successfulDeletes = deleteResults.filter(r => r.success).length;

        console.log(`   🎯 Removed ${successfulDeletes}/${connectionsToRemove.length} connections`);

        return {
            success: true,
            connectionsFound: connections.length,
            connectionsToRemove: connectionsToRemove.length,
            removedConnections: successfulDeletes,
            deleteResults
        };

    } catch (error) {
        console.error('❌ Error removing business connections:', error);
        return {
            success: false,
            error: error.message,
            connectionsFound: 0,
            connectionsToRemove: 0,
            removedConnections: 0
        };
    }
}

/**
 * Handle user logout - remove all connections for the business/user
 */
async function handleUserLogout(businessId, userId, options = {}) {
    try {
        console.log(`🔄 Processing user logout for business: ${businessId}, user: ${userId}`);
        
        const {
            source = 'user_logout',
            ...otherOptions
        } = options;

        // Remove all connections (both virtual and real) for this business/user
        const result = await removeBusinessConnections(businessId, userId, {
            source,
            connectionType: null, // Remove all types of connections
            ...otherOptions
        });

        console.log(`✅ User logout processing completed`);
        console.log(`   Connections found: ${result.connectionsFound}`);
        console.log(`   Connections removed: ${result.removedConnections}`);

        return {
            success: result.success,
            message: `Logout processed for business ${businessId}`,
            connectionsRemoved: result.removedConnections,
            connectionsFound: result.connectionsFound,
            businessId,
            userId,
            source
        };

    } catch (error) {
        console.error('❌ Error handling user logout:', error);
        return {
            success: false,
            message: 'Failed to process user logout',
            error: error.message,
            businessId,
            userId
        };
    }
}

/**
 * Comprehensive logout cleanup with multiple options
 */
async function performLogoutCleanup(businessId, userId, options = {}) {
    try {
        const {
            forceDisconnectReal = false,
            cleanupStale = false,
            dryRun = false
        } = options;

        console.log(`🧹 Performing comprehensive logout cleanup`);
        console.log(`   Business: ${businessId}, User: ${userId}`);
        console.log(`   Force disconnect real: ${forceDisconnectReal}`);
        console.log(`   Cleanup stale: ${cleanupStale}`);
        console.log(`   Dry run: ${dryRun}`);

        const results = {};

        // Step 1: Remove login tracking connections (VIRTUAL)
        console.log('   Step 1: Removing virtual connections...');
        results.virtualCleanup = await removeBusinessConnections(businessId, userId, {
            connectionType: 'VIRTUAL',
            source: 'logout_cleanup',
            dryRun
        });

        // Step 2: Optionally remove real WebSocket connections (forced logout)
        if (forceDisconnectReal) {
            console.log('   Step 2: Force disconnecting real connections...');
            results.realCleanup = await removeBusinessConnections(businessId, userId, {
                connectionType: 'REAL',
                source: 'forced_logout',
                dryRun
            });
        }

        // Step 3: Clean up any stale connections
        if (cleanupStale) {
            console.log('   Step 3: Cleaning up stale connections...');
            results.staleCleanup = await cleanupBusinessStaleConnections(businessId, { dryRun });
        }

        const totalRemoved = (results.virtualCleanup?.removedConnections || 0) + 
                           (results.realCleanup?.removedConnections || 0) + 
                           (results.staleCleanup?.removedConnections || 0);

        console.log(`✅ Comprehensive cleanup completed - ${totalRemoved} total connections cleaned`);

        return {
            success: true,
            message: 'Comprehensive logout cleanup completed',
            totalConnectionsRemoved: totalRemoved,
            results,
            businessId,
            userId
        };

    } catch (error) {
        console.error('❌ Error in comprehensive logout cleanup:', error);
        return {
            success: false,
            message: 'Failed to perform comprehensive logout cleanup',
            error: error.message,
            businessId,
            userId
        };
    }
}

/**
 * Clean up stale connections for a specific business
 */
async function cleanupBusinessStaleConnections(businessId, options = {}) {
    try {
        const { dryRun = false } = options;
        
        console.log(`🧹 Cleaning up stale connections for business: ${businessId}`);
        
        // Define staleness criteria (connections older than 2 hours)
        const staleThreshold = Date.now() - (2 * 60 * 60 * 1000); // 2 hours ago
        
        // Query for all connections for this business
        const queryParams = {
            TableName: TABLE_NAME,
            IndexName: 'userId-connectedAt-index',
            KeyConditionExpression: 'userId = :businessId',
            ExpressionAttributeValues: {
                ':businessId': businessId
            }
        };

        const queryResult = await dynamodb.send(new QueryCommand(queryParams));
        const allConnections = queryResult.Items || [];

        // Filter for stale connections
        const staleConnections = allConnections.filter(conn => {
            const connectedAt = new Date(conn.connectedAt).getTime();
            return connectedAt < staleThreshold;
        });

        console.log(`   Found ${staleConnections.length} stale connections out of ${allConnections.length} total`);

        if (dryRun) {
            console.log('   🔍 DRY RUN - Would remove stale connections:', staleConnections.map(c => ({
                connectionId: c.connectionId,
                type: c.connectionType,
                connectedAt: c.connectedAt,
                ageHours: Math.round((Date.now() - new Date(c.connectedAt).getTime()) / (60 * 60 * 1000))
            })));
            return {
                success: true,
                staleConnectionsFound: staleConnections.length,
                removedConnections: 0,
                dryRun: true
            };
        }

        // Remove stale connections
        const deletePromises = staleConnections.map(async (connection) => {
            try {
                const deleteParams = {
                    TableName: TABLE_NAME,
                    Key: {
                        PK: connection.PK,
                        SK: connection.SK
                    }
                };

                await dynamodb.send(new DeleteCommand(deleteParams));
                console.log(`   ✅ Removed stale connection: ${connection.connectionId}`);
                return { success: true, connectionId: connection.connectionId };
            } catch (error) {
                console.error(`   ❌ Failed to remove stale connection ${connection.connectionId}:`, error.message);
                return { success: false, connectionId: connection.connectionId, error: error.message };
            }
        });

        const deleteResults = await Promise.all(deletePromises);
        const successfulDeletes = deleteResults.filter(r => r.success).length;

        console.log(`   🎯 Removed ${successfulDeletes}/${staleConnections.length} stale connections`);

        return {
            success: true,
            staleConnectionsFound: staleConnections.length,
            removedConnections: successfulDeletes,
            businessId
        };

    } catch (error) {
        console.error('❌ Error cleaning up stale connections:', error);
        return {
            success: false,
            error: error.message,
            staleConnectionsFound: 0,
            removedConnections: 0,
            businessId
        };
    }
}

module.exports = {
    handleUserLogout,
    performLogoutCleanup,
    cleanupBusinessStaleConnections,
    removeBusinessConnections
};
