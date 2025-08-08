const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, QueryCommand, ScanCommand } = require("@aws-sdk/lib-dynamodb");

const dynamoDBClient = new DynamoDBClient({ region: process.env.DYNAMODB_REGION });
const dynamodb = DynamoDBDocumentClient.from(dynamoDBClient);

// Environment variables
const ORDERS_TABLE = process.env.ORDERS_TABLE;
const PRODUCTS_TABLE = process.env.PRODUCTS_TABLE;
const BUSINESSES_TABLE = process.env.BUSINESSES_TABLE;

// Helper function to create response
function createResponse(statusCode, body) {
    return {
        statusCode: statusCode,
        headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
            "Content-Type": "application/json"
        },
        body: JSON.stringify(body)
    };
}

exports.handler = async (event) => {
    console.log('Demand Forecasting Handler - Event:', JSON.stringify(event, null, 2));

    const { httpMethod, pathParameters, queryStringParameters } = event;
    const businessId = pathParameters?.businessId;

    try {
        switch (httpMethod) {
            case 'GET':
                if (event.resource === '/analytics/demand-forecast/{businessId}') {
                    return await handleGetDemandForecast(dynamodb, businessId, queryStringParameters);
                } else if (event.resource === '/analytics/inventory-optimization/{businessId}') {
                    return await handleGetInventoryOptimization(dynamodb, businessId);
                } else if (event.resource === '/analytics/peak-hours/{businessId}') {
                    return await handleGetPeakHours(dynamodb, businessId);
                } else if (event.resource === '/analytics/seasonal-trends/{businessId}') {
                    return await handleGetSeasonalTrends(dynamodb, businessId);
                }
                break;
            case 'OPTIONS':
                return createResponse(200, { message: 'CORS preflight response' });
        }

        return createResponse(404, { success: false, message: 'Endpoint not found' });
    } catch (error) {
        console.error('Error in demand forecasting handler:', error);
        return createResponse(500, { success: false, message: 'Internal server error' });
    }
};

// Get demand forecast for the business
async function handleGetDemandForecast(dynamodb, businessId, queryParams) {
    try {
        const timeframe = queryParams?.timeframe || '7d'; // 1d, 7d, 30d
        const includeWeather = queryParams?.includeWeather === 'true';
        
        console.log(`Getting demand forecast for business: ${businessId}, timeframe: ${timeframe}`);

        // Get historical orders for the business
        const ordersParams = {
            TableName: ORDERS_TABLE,
            IndexName: 'BusinessIdIndex',
            KeyConditionExpression: 'businessId = :businessId',
            ExpressionAttributeValues: {
                ':businessId': businessId
            }
        };

        const ordersResult = await dynamodb.send(new QueryCommand(ordersParams));
        const orders = ordersResult.Items || [];

        // Analyze historical data
        const analysis = analyzeHistoricalData(orders, timeframe);
        
        // Generate predictions based on patterns
        const predictions = generateDemandPredictions(analysis, timeframe);
        
        // Add weather impact if requested (mock implementation)
        if (includeWeather) {
            predictions.weatherImpact = await getWeatherImpact(businessId);
        }

        return createResponse(200, {
            success: true,
            data: {
                businessId,
                timeframe,
                forecast: predictions,
                confidence: calculateConfidence(analysis),
                recommendations: generateRecommendations(predictions)
            }
        });
    } catch (error) {
        console.error('Error getting demand forecast:', error);
        return createResponse(500, { success: false, message: 'Failed to generate demand forecast' });
    }
}

// Get inventory optimization recommendations
async function handleGetInventoryOptimization(dynamodb, businessId) {
    try {
        console.log(`Getting inventory optimization for business: ${businessId}`);

        // Get products for the business
        const productsParams = {
            TableName: PRODUCTS_TABLE,
            IndexName: 'BusinessIdIndex',
            KeyConditionExpression: 'businessId = :businessId',
            ExpressionAttributeValues: {
                ':businessId': businessId
            }
        };

        const productsResult = await dynamodb.send(new QueryCommand(productsParams));
        const products = productsResult.Items || [];

        // Get recent orders to analyze product performance
        const ordersParams = {
            TableName: ORDERS_TABLE,
            IndexName: 'BusinessIdIndex',
            KeyConditionExpression: 'businessId = :businessId',
            ExpressionAttributeValues: {
                ':businessId': businessId
            }
        };

        const ordersResult = await dynamodb.send(new QueryCommand(ordersParams));
        const orders = ordersResult.Items || [];

        // Analyze product performance and generate optimization recommendations
        const optimization = generateInventoryOptimization(products, orders);

        return createResponse(200, {
            success: true,
            data: {
                businessId,
                totalProducts: products.length,
                optimization,
                potentialSavings: optimization.estimatedSavings,
                timestamp: new Date().toISOString()
            }
        });
    } catch (error) {
        console.error('Error getting inventory optimization:', error);
        return createResponse(500, { success: false, message: 'Failed to generate inventory optimization' });
    }
}

// Get peak hours analysis
async function handleGetPeakHours(dynamodb, businessId) {
    try {
        console.log(`Getting peak hours analysis for business: ${businessId}`);

        const ordersParams = {
            TableName: ORDERS_TABLE,
            IndexName: 'BusinessIdIndex',
            KeyConditionExpression: 'businessId = :businessId',
            ExpressionAttributeValues: {
                ':businessId': businessId
            }
        };

        const ordersResult = await dynamodb.send(new QueryCommand(ordersParams));
        const orders = ordersResult.Items || [];

        const peakAnalysis = analyzePeakHours(orders);

        return createResponse(200, {
            success: true,
            data: {
                businessId,
                analysis: peakAnalysis,
                recommendations: generateStaffingRecommendations(peakAnalysis)
            }
        });
    } catch (error) {
        console.error('Error getting peak hours analysis:', error);
        return createResponse(500, { success: false, message: 'Failed to analyze peak hours' });
    }
}

// Get seasonal trends analysis
async function handleGetSeasonalTrends(dynamodb, businessId) {
    try {
        console.log(`Getting seasonal trends for business: ${businessId}`);

        const ordersParams = {
            TableName: ORDERS_TABLE,
            IndexName: 'BusinessIdIndex',
            KeyConditionExpression: 'businessId = :businessId',
            ExpressionAttributeValues: {
                ':businessId': businessId
            }
        };

        const ordersResult = await dynamodb.send(new QueryCommand(ordersParams));
        const orders = ordersResult.Items || [];

        const seasonalAnalysis = analyzeSeasonalTrends(orders);

        return createResponse(200, {
            success: true,
            data: {
                businessId,
                trends: seasonalAnalysis,
                menuRecommendations: generateMenuRecommendations(seasonalAnalysis)
            }
        });
    } catch (error) {
        console.error('Error getting seasonal trends:', error);
        return createResponse(500, { success: false, message: 'Failed to analyze seasonal trends' });
    }
}

// Helper functions for AI/ML analysis

function analyzeHistoricalData(orders, timeframe) {
    const now = new Date();
    let cutoffDate;
    
    switch (timeframe) {
        case '1d':
            cutoffDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
            break;
        case '7d':
            cutoffDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
            break;
        case '30d':
            cutoffDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
            break;
        default:
            cutoffDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    }

    const relevantOrders = orders.filter(order => {
        const orderDate = new Date(order.createdAt);
        return orderDate >= cutoffDate && order.status === 'delivered';
    });

    // Analyze patterns
    const hourlyData = {};
    const dailyData = {};
    const itemPerformance = {};

    relevantOrders.forEach(order => {
        const date = new Date(order.createdAt);
        const hour = date.getHours();
        const dayOfWeek = date.getDay();
        const dayKey = date.toISOString().split('T')[0];

        // Hourly patterns
        hourlyData[hour] = (hourlyData[hour] || 0) + 1;

        // Daily patterns
        dailyData[dayOfWeek] = (dailyData[dayOfWeek] || 0) + 1;

        // Item performance
        if (order.items) {
            order.items.forEach(item => {
                const key = item.dishName || item.name;
                if (!itemPerformance[key]) {
                    itemPerformance[key] = { quantity: 0, revenue: 0 };
                }
                itemPerformance[key].quantity += item.quantity || 1;
                itemPerformance[key].revenue += (item.price * item.quantity) || 0;
            });
        }
    });

    return {
        totalOrders: relevantOrders.length,
        hourlyPatterns: hourlyData,
        dailyPatterns: dailyData,
        itemPerformance,
        averageOrderValue: relevantOrders.length > 0 ? 
            relevantOrders.reduce((sum, order) => sum + order.totalAmount, 0) / relevantOrders.length : 0
    };
}

function generateDemandPredictions(analysis, timeframe) {
    const predictions = {
        expectedOrders: [],
        peakHours: [],
        popularItems: [],
        revenueEstimate: 0
    };

    // Find peak hours
    const hourlyEntries = Object.entries(analysis.hourlyPatterns);
    const avgHourlyOrders = hourlyEntries.reduce((sum, [hour, count]) => sum + count, 0) / hourlyEntries.length;
    
    predictions.peakHours = hourlyEntries
        .filter(([hour, count]) => count > avgHourlyOrders * 1.2)
        .map(([hour, count]) => ({ hour: parseInt(hour), expectedOrders: Math.round(count * 1.1) }))
        .sort((a, b) => b.expectedOrders - a.expectedOrders);

    // Popular items prediction
    const itemEntries = Object.entries(analysis.itemPerformance);
    predictions.popularItems = itemEntries
        .sort((a, b) => b[1].quantity - a[1].quantity)
        .slice(0, 10)
        .map(([item, data]) => ({
            name: item,
            predictedQuantity: Math.round(data.quantity * 1.05),
            predictedRevenue: data.revenue * 1.05
        }));

    // Revenue estimate
    predictions.revenueEstimate = analysis.averageOrderValue * analysis.totalOrders * 1.1;

    return predictions;
}

function generateInventoryOptimization(products, orders) {
    const productPerformance = {};
    
    // Calculate performance metrics for each product
    products.forEach(product => {
        productPerformance[product.id] = {
            name: product.name,
            currentStock: product.stock || 0,
            averageDaily: 0,
            recommendedStock: 0,
            turnoverRate: 0,
            status: 'optimal'
        };
    });

    // Analyze order data for product performance
    orders.forEach(order => {
        if (order.items) {
            order.items.forEach(item => {
                const productId = item.productId || item.id;
                if (productPerformance[productId]) {
                    productPerformance[productId].averageDaily += (item.quantity || 1);
                }
            });
        }
    });

    // Generate recommendations
    const recommendations = [];
    let totalSavings = 0;

    Object.values(productPerformance).forEach(product => {
        // Calculate daily average over last 30 days
        product.averageDaily = Math.round(product.averageDaily / 30);
        
        // Recommend 7 days of stock plus safety buffer
        product.recommendedStock = Math.max(product.averageDaily * 10, 5);
        
        // Determine status
        if (product.currentStock > product.recommendedStock * 1.5) {
            product.status = 'overstocked';
            totalSavings += (product.currentStock - product.recommendedStock) * 5; // Assume $5 per unit
            recommendations.push({
                type: 'reduce',
                product: product.name,
                action: `Reduce stock from ${product.currentStock} to ${product.recommendedStock}`,
                priority: 'medium',
                savings: (product.currentStock - product.recommendedStock) * 5
            });
        } else if (product.currentStock < product.averageDaily * 3) {
            product.status = 'understocked';
            recommendations.push({
                type: 'increase',
                product: product.name,
                action: `Increase stock from ${product.currentStock} to ${product.recommendedStock}`,
                priority: 'high',
                risk: 'stockout'
            });
        }
    });

    return {
        products: Object.values(productPerformance),
        recommendations,
        estimatedSavings: Math.round(totalSavings),
        totalProducts: products.length,
        overstockedItems: recommendations.filter(r => r.type === 'reduce').length,
        understockedItems: recommendations.filter(r => r.type === 'increase').length
    };
}

function analyzePeakHours(orders) {
    const hourlyData = {};
    const dailyData = {};
    
    orders.forEach(order => {
        const date = new Date(order.createdAt);
        const hour = date.getHours();
        const dayOfWeek = date.getDay();
        
        hourlyData[hour] = (hourlyData[hour] || 0) + 1;
        dailyData[dayOfWeek] = (dailyData[dayOfWeek] || 0) + 1;
    });

    const peakHours = Object.entries(hourlyData)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 3)
        .map(([hour, count]) => ({ hour: parseInt(hour), orderCount: count }));

    const peakDays = Object.entries(dailyData)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 3)
        .map(([day, count]) => ({ dayOfWeek: parseInt(day), orderCount: count }));

    return {
        peakHours,
        peakDays,
        totalOrders: orders.length,
        avgOrdersPerHour: Math.round(orders.length / 24),
        businessHours: peakHours.map(h => h.hour).join(', ')
    };
}

function generateStaffingRecommendations(peakAnalysis) {
    return peakAnalysis.peakHours.map(peak => ({
        time: `${peak.hour}:00 - ${peak.hour + 1}:00`,
        recommendedStaff: Math.max(Math.ceil(peak.orderCount / 10), 2),
        reason: `Peak hour with ${peak.orderCount} orders`,
        priority: peak.orderCount > 20 ? 'high' : 'medium'
    }));
}

function analyzeSeasonalTrends(orders) {
    const monthlyData = {};
    const seasonalItems = {};
    
    orders.forEach(order => {
        const date = new Date(order.createdAt);
        const month = date.getMonth();
        
        monthlyData[month] = (monthlyData[month] || 0) + 1;
        
        if (order.items) {
            order.items.forEach(item => {
                const key = item.dishName || item.name;
                if (!seasonalItems[key]) {
                    seasonalItems[key] = {};
                }
                seasonalItems[key][month] = (seasonalItems[key][month] || 0) + (item.quantity || 1);
            });
        }
    });

    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    const trends = Object.entries(monthlyData).map(([month, count]) => ({
        month: monthNames[month],
        orders: count
    }));

    return {
        monthlyTrends: trends,
        seasonalItems: Object.entries(seasonalItems)
            .map(([item, months]) => ({
                name: item,
                bestMonths: Object.entries(months)
                    .sort((a, b) => b[1] - a[1])
                    .slice(0, 3)
                    .map(([month, count]) => ({ month: monthNames[month], orders: count }))
            }))
            .slice(0, 10)
    };
}

function generateMenuRecommendations(seasonalAnalysis) {
    const currentMonth = new Date().getMonth();
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return {
        currentMonth: monthNames[currentMonth],
        recommendations: [
            {
                type: 'promote',
                action: 'Feature seasonal favorites',
                impact: 'high',
                description: 'Promote items that historically perform well this month'
            },
            {
                type: 'add',
                action: 'Introduce seasonal specials',
                impact: 'medium',
                description: 'Add weather-appropriate items to capture seasonal demand'
            },
            {
                type: 'remove',
                action: 'Reduce slow-moving items',
                impact: 'low',
                description: 'Temporarily remove items that underperform in this season'
            }
        ]
    };
}

async function getWeatherImpact(businessId) {
    // Mock weather impact - in production, integrate with weather API
    return {
        temperature: 'mild',
        conditions: 'sunny',
        impact: {
            coldDrinks: '+15%',
            hotSoups: '-10%',
            deliveryOrders: '+5%'
        }
    };
}

function calculateConfidence(analysis) {
    const orderCount = analysis.totalOrders;
    
    if (orderCount > 100) return 'high';
    if (orderCount > 50) return 'medium';
    return 'low';
}

function generateRecommendations(predictions) {
    return [
        {
            type: 'staffing',
            message: `Increase staff during peak hours: ${predictions.peakHours.map(p => `${p.hour}:00`).join(', ')}`,
            priority: 'high'
        },
        {
            type: 'inventory',
            message: `Stock up on top items: ${predictions.popularItems.slice(0, 3).map(i => i.name).join(', ')}`,
            priority: 'medium'
        },
        {
            type: 'revenue',
            message: `Expected revenue increase: ${Math.round(predictions.revenueEstimate)} IQD`,
            priority: 'info'
        }
    ];
}
