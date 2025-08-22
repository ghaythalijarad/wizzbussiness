import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/business.dart';
import '../l10n/app_localizations.dart';
import 'dart:math' as math;
import '../models/enhanced_analytics_data.dart';
import '../services/demand_forecasting_service.dart';
import '../widgets/material_card.dart';
import '../theme/theme_extensions.dart';

class AnalyticsPage extends StatefulWidget {
  final Business business;
  final List<Order> orders;
  final VoidCallback? onNavigateToOrders;
  final Function(String, OrderStatus)? onOrderUpdated;
  final bool embedded;

  const AnalyticsPage({
    Key? key,
    required this.business,
    required this.orders,
    this.onNavigateToOrders,
    this.onOrderUpdated,
    this.embedded = false,
  }) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTimeRange = 0; // 0: Today, 1: Week, 2: Month, 3: Year
  DemandForecastingData? _demandForecast;
  bool _isLoadingForecast = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Updated to 5 tabs
    _loadDemandForecast();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load demand forecasting data from the AI/ML service
  Future<void> _loadDemandForecast() async {
    setState(() {
      _isLoadingForecast = true;
    });

    try {
      // For development, use mock data. In production, use API call:
      // final forecast = await DemandForecastingService.getDemandForecast(
      //   businessId: widget.business.id,
      // );
      
      // Using mock data for now
      final forecast = DemandForecastingService.generateMockData();
      
      setState(() {
        _demandForecast = forecast;
        _isLoadingForecast = false;
      });
    } catch (e) {
      print('Error loading demand forecast: $e');
      setState(() {
        _isLoadingForecast = false;
      });
    }
  }

  String get businessName => widget.business.name;

  AnalyticsData _generateAnalyticsData(AppLocalizations loc) {
    // Filter for delivered orders for revenue calculations
    final deliveredOrders = widget.orders
        .where((order) => order.status == OrderStatus.delivered)
        .toList();

    // Calculate real analytics from orders
    double totalRevenue =
        deliveredOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
    double dailyRevenue = deliveredOrders
        .where((o) => o.createdAt
            .isAfter(DateTime.now().subtract(const Duration(days: 1))))
        .fold(0.0, (sum, o) => sum + o.totalAmount);
    double weeklyRevenue = deliveredOrders
        .where((o) => o.createdAt
            .isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .fold(0.0, (sum, o) => sum + o.totalAmount);
    double monthlyRevenue = deliveredOrders
        .where((o) => o.createdAt
            .isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .fold(0.0, (sum, o) => sum + o.totalAmount);

    double averageOrderValue = deliveredOrders.isEmpty
        ? 0.0
        : totalRevenue / deliveredOrders.length;

    // Calculate item statistics from actual orders
    Map<String, int> itemQuantities = {};
    Map<String, double> itemRevenues = {};

    for (final order in widget.orders) {
      for (final item in order.items) {
        final itemName = item.dishName;
        itemQuantities[itemName] =
            (itemQuantities[itemName] ?? 0) + item.quantity;
        itemRevenues[itemName] =
            (itemRevenues[itemName] ?? 0.0) + (item.price * item.quantity);
      }
    }

    // Sort items by quantity sold (descending for top, ascending for least)
    final sortedItems = itemQuantities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Generate top selling items
    final topSellingItems = sortedItems
        .take(5)
        .map((entry) => TopSellingItem(
              itemName: entry.key,
              soldQuantity: entry.value,
              revenue: itemRevenues[entry.key] ?? 0.0,
            ))
        .toList();

    // Generate least ordered items (reverse order, take bottom items)
    final leastOrderedItems = sortedItems.reversed
        .take(3)
        .map((entry) => LeastOrderedItem(
              itemName: entry.key,
              soldQuantity: entry.value,
              revenue: itemRevenues[entry.key] ?? 0.0,
            ))
        .toList();

    // Use fallback data if no real order data
    final fallbackTopSelling = [
      TopSellingItem(itemName: loc.sampleItem, soldQuantity: 25, revenue: 750),
      TopSellingItem(itemName: loc.specialDish, soldQuantity: 18, revenue: 540),
      TopSellingItem(itemName: loc.popularItem, soldQuantity: 12, revenue: 360),
    ];

    final fallbackLeastOrdered = [
      LeastOrderedItem(
          itemName: "Seasonal Special", soldQuantity: 2, revenue: 40),
      LeastOrderedItem(
          itemName: "Premium Dessert", soldQuantity: 3, revenue: 75),
      LeastOrderedItem(
          itemName: "Specialty Drink", soldQuantity: 4, revenue: 60),
    ];

    // Generate sample revenue chart data
    List<DailyRevenue> revenueChart = List.generate(7, (index) {
      return DailyRevenue(
        date: DateTime.now().subtract(Duration(days: 6 - index)),
        revenue: 100 + (math.Random().nextDouble() * 500),
      );
    });

    return AnalyticsData(
      totalRevenue: totalRevenue,
      dailyRevenue: dailyRevenue,
      weeklyRevenue: weeklyRevenue,
      monthlyRevenue: monthlyRevenue,
      totalOrders: widget.orders.length,
      averageOrderValue: averageOrderValue,
      topSellingItems:
          topSellingItems.isNotEmpty ? topSellingItems : fallbackTopSelling,
      leastOrderedItems: leastOrderedItems.isNotEmpty
          ? leastOrderedItems
          : fallbackLeastOrdered,
      recentReviews: [
        ReviewData(
          customerName: "Ahmed M.",
          rating: 4.5,
          comment: "Great food and fast delivery!",
          createdAt: DateTime.now().subtract(Duration(hours: 2)),
          orderId: "ORD-001",
        ),
        ReviewData(
          customerName: "Sarah K.",
          rating: 5.0,
          comment: "Excellent service, highly recommended!",
          createdAt: DateTime.now().subtract(Duration(hours: 6)),
          orderId: "ORD-002",
        ),
        ReviewData(
          customerName: "Mohammed A.",
          rating: 4.0,
          comment: "Good quality food, will order again.",
          createdAt: DateTime.now().subtract(Duration(days: 1)),
          orderId: "ORD-003",
        ),
      ],
      ordersByStatus: {
        for (var status in OrderStatus.values)
          status: widget.orders.where((o) => o.status == status).length
      },
      revenueChart: revenueChart,
      growthRate: 12.5,
      customersServed: widget.orders.length,
      cancellationRate: 2.1,
      averagePreparationTime: 18.5,
      averageRating: 4.3,
      totalReviews: 156,
      demandForecast: _demandForecast, // Include AI forecasting data
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final analytics = _generateAnalyticsData(loc);
    final theme = Theme.of(context);

    final body = Column(
      children: [
        // Material You Time Range Selector
        MaterialCard.filled(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.date_range,
                color: context.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Time Period',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface,
                    ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildMaterialTimeRangeChip(loc.today, 0),
                      SizedBox(width: 8),
                      _buildMaterialTimeRangeChip(loc.week, 1),
                      SizedBox(width: 8),
                      _buildMaterialTimeRangeChip(loc.month, 2),
                      SizedBox(width: 8),
                      _buildMaterialTimeRangeChip(loc.year, 3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tab Bar
        TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.primaryColor,
          indicatorWeight: 3,
          tabs: [
            Tab(text: loc.overview),
            Tab(text: loc.revenue),
            Tab(text: loc.performance),
            Tab(text: loc.reviewsAndInsights),
            Tab(text: 'AI Forecasting'), // New AI/ML tab
          ],
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(analytics, loc, theme),
              _buildRevenueTab(analytics, loc, theme),
              _buildPerformanceTab(analytics, loc, theme),
              _buildReviewsTab(analytics, loc, theme),
              _buildAIForecastingTab(
                  analytics, loc, theme), // New AI forecasting tab
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.analytics),
      ),
      body: body,
    );
  }

  Widget _buildOverviewTab(
      AnalyticsData analytics, AppLocalizations loc, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Revenue Cards Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildRevenueCard(
                title: loc.totalRevenue,
                value: "${analytics.totalRevenue.toStringAsFixed(2)} IQD",
                icon: Icons.monetization_on,
                color: const Color(0xFF4CAF50),
                growth: "+${analytics.growthRate}%",
              ),
              _buildRevenueCard(
                title: loc.todaysRevenue,
                value: "${analytics.dailyRevenue.toStringAsFixed(2)} IQD",
                icon: Icons.today,
                color: const Color(0xFF2196F3),
                growth: "+8.2%",
              ),
              _buildRevenueCard(
                title: loc.totalOrders,
                value: "${analytics.totalOrders}",
                icon: Icons.shopping_cart,
                color: const Color(0xFFFF9800),
                growth: "+15.1%",
              ),
              _buildRevenueCard(
                title: loc.avgOrderValue,
                value: "${analytics.averageOrderValue.toStringAsFixed(2)} IQD",
                icon: Icons.analytics,
                color: const Color(0xFF9C27B0),
                growth: "+5.8%",
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Stats Row
          _buildQuickStatsCard(analytics, loc),

          const SizedBox(height: 24),

          // Top Selling Items
          _buildTopSellingItemsCard(analytics, loc),

          const SizedBox(height: 24),

          // Quick Insights Row
          Row(
            children: [
              Expanded(
                child: _buildQuickInsightCard(
                  title: loc.bestPerformer,
                  subtitle: analytics.topSellingItems.isNotEmpty
                      ? analytics.topSellingItems.first.itemName
                      : "N/A",
                  value: analytics.topSellingItems.isNotEmpty
                      ? loc.quickInsightSoldCount(
                          analytics.topSellingItems.first.soldQuantity)
                      : "0 sold",
                  icon: Icons.trending_up,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickInsightCard(
                  title: loc.needsAttention,
                  subtitle: analytics.leastOrderedItems.isNotEmpty
                      ? analytics.leastOrderedItems.first.itemName
                      : "N/A",
                  value: analytics.leastOrderedItems.isNotEmpty
                      ? loc.quickInsightSoldCount(
                          analytics.leastOrderedItems.first.soldQuantity)
                      : "0 sold",
                  icon: Icons.trending_down,
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab(
      AnalyticsData analytics, AppLocalizations loc, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Revenue Chart Card
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.revenueTrend,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "+${analytics.growthRate}%",
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 250,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Revenue Chart\n(Chart implementation pending)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Revenue Breakdown
          _buildRevenueBreakdownCard(analytics, loc),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(
      AnalyticsData analytics, AppLocalizations loc, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Performance Metrics
          _buildPerformanceMetricsCard(analytics, loc),

          const SizedBox(height: 24),

          // Order Status Distribution
          _buildOrderStatusChart(analytics, loc),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(
      AnalyticsData analytics, AppLocalizations loc, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Customer Reviews & Ratings
          _buildCustomerReviewsCard(analytics, loc),

          const SizedBox(height: 24),

          // Least Ordered Items
          _buildLeastOrderedItemsCard(analytics, loc),

          const SizedBox(height: 24),

          // Business Insights
          _buildBusinessInsightsCard(analytics, loc),
        ],
      ),
    );
  }

  Widget _buildRevenueCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String growth,
  }) {
    return MaterialCard(
      gradient: CardGradient.primary, // Use primary gradient for now
      elevation: CardElevation.medium,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  growth,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard(AnalyticsData analytics, AppLocalizations loc) {
    return MaterialCard.elevated(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.quickStats,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickStatItem(
                  loc.customersServed,
                  "${analytics.customersServed}",
                  Icons.people,
                  context.colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildQuickStatItem(
                  loc.cancellationRate,
                  "${analytics.cancellationRate}%",
                  Icons.cancel,
                  context.colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellingItemsCard(
      AnalyticsData analytics, AppLocalizations loc) {
    return MaterialCard.elevated(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.topSellingItems,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          ...analytics.topSellingItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return MaterialCard.filled(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getItemColor(index),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          loc.itemSoldQuantity(item.soldQuantity),
                          style: TextStyle(
                            color: context.colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${item.revenue.toStringAsFixed(2)} IQD",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        loc.revenueLabel,
                        style: TextStyle(
                          color: context.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdownCard(
      AnalyticsData analytics, AppLocalizations loc) {
    return MaterialCard.elevated(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.revenueBreakdown,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 20),
          _buildRevenueBreakdownItem(loc.dailyRevenue, analytics.dailyRevenue,
              context.colorScheme.primary),
          _buildRevenueBreakdownItem(loc.weeklyRevenue,
              analytics.weeklyRevenue,
              context.colorScheme.secondary),
          _buildRevenueBreakdownItem(loc.monthlyRevenue,
              analytics.monthlyRevenue, context.colorScheme.tertiary),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdownItem(String title, double amount, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            "${amount.toStringAsFixed(2)} IQD",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetricsCard(
      AnalyticsData analytics, AppLocalizations loc) {
    return MaterialCard.elevated(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.performanceMetrics,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceMetric(
                  loc.avgPrepTime,
                  "${analytics.averagePreparationTime.toStringAsFixed(1)} min",
                  Icons.timer,
                  context.colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildPerformanceMetric(
                  loc.successRate,
                  "${(100 - analytics.cancellationRate).toStringAsFixed(1)}%",
                  Icons.check_circle,
                  context.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusChart(AnalyticsData analytics, AppLocalizations loc) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.ordersByStatus,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Order Status Chart\n(Chart implementation pending)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: analytics.ordersByStatus.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(entry.key),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${_localizedOrderStatus(loc, entry.key)}: ${entry.value}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    return context.getStatusColor(status);
  }

  Color _getItemColor(int index) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFF96CEB4),
      const Color(0xFFFECE54),
    ];
    return colors[index % colors.length];
  }

  String _localizedOrderStatus(AppLocalizations loc, OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return loc.orderStatusPending;
      case OrderStatus.confirmed:
        return loc.orderStatusConfirmed;
      case OrderStatus.preparing:
        return loc.orderStatusPreparing;
      case OrderStatus.ready:
        return loc.orderStatusReady;
      case OrderStatus.onTheWay:
        return loc.orderStatusOnTheWay;
      case OrderStatus.delivered:
        return loc.orderStatusDelivered;
      case OrderStatus.cancelled:
        return loc.orderStatusCancelled;
      case OrderStatus.returned:
        return loc.orderStatusReturned;
      case OrderStatus.expired:
        return loc.orderStatusExpired;
    }
  }

  Widget _buildCustomerReviewsCard(
      AnalyticsData analytics, AppLocalizations loc) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.customerReviews,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFF9800),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${analytics.averageRating.toStringAsFixed(1)}",
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...analytics.recentReviews
                .map((review) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                review.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < review.rating.floor()
                                        ? Icons.star
                                        : index < review.rating
                                            ? Icons.star_half
                                            : Icons.star_border,
                                    color: const Color(0xFFFF9800),
                                    size: 16,
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            review.comment,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Order: ${review.orderId}",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatTimeAgo(review.createdAt),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeastOrderedItemsCard(
      AnalyticsData analytics, AppLocalizations loc) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.leastOrderedItems,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.leastOrderedItemsDescription,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ...analytics.leastOrderedItems.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.trending_down,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            loc.onlySoldCount(item.soldQuantity),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${item.revenue.toStringAsFixed(2)} IQD",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          loc.revenueLabel,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInsightsCard(
      AnalyticsData analytics, AppLocalizations loc) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.businessInsights,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
              icon: Icons.trending_up,
              title: loc.growingPopularity,
              description:
                  loc.growingPopularityDescription(analytics.growthRate),
              color: const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              icon: Icons.star_rate,
              title: loc.customerSatisfaction,
              description: loc.customerSatisfactionDescription(
                  analytics.averageRating.toStringAsFixed(1),
                  analytics.totalReviews),
              color: const Color(0xFFFF9800),
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              icon: Icons.schedule,
              title: loc.efficientService,
              description: loc.efficientServiceDescription(
                  analytics.averagePreparationTime.toStringAsFixed(1)),
              color: const Color(0xFF2196F3),
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              icon: Icons.people,
              title: loc.customerBase,
              description: loc.customerBaseDescription(
                  analytics.customersServed, analytics.cancellationRate),
              color: const Color(0xFF9C27B0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return "${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago";
    } else {
      return "Just now";
    }
  }

  Widget _buildQuickInsightCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the AI Forecasting tab with demand predictions and insights
  Widget _buildAIForecastingTab(AnalyticsData analytics, AppLocalizations loc, ThemeData theme) {
    if (_isLoadingForecast) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading AI predictions...'),
          ],
        ),
      );
    }

    if (_demandForecast == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Unable to load AI forecasting data',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDemandForecast,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Confidence Score Header
          _buildAIConfidenceHeader(_demandForecast!, theme),
          const SizedBox(height: 20),

          // Demand Predictions Section
          _buildDemandPredictionsSection(_demandForecast!, theme),
          const SizedBox(height: 20),

          // Peak Hours Analysis Section
          _buildPeakHoursSection(_demandForecast!.peakHours, theme),
          const SizedBox(height: 20),

          // Business Recommendations Section
          _buildRecommendationsSection(_demandForecast!.recommendations, theme),
          const SizedBox(height: 20),

          // Seasonal Trends Section
          _buildSeasonalTrendsSection(_demandForecast!.seasonalTrends, theme),
        ],
      ),
    );
  }

  Widget _buildAIConfidenceHeader(DemandForecastingData forecast, ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withOpacity(0.1),
              theme.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.psychology, color: theme.primaryColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Demand Forecasting',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confidence Score: ${(forecast.confidenceScore * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Updated: ${_formatDateTime(forecast.lastUpdated)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            CircularProgressIndicator(
              value: forecast.confidenceScore,
              backgroundColor: Colors.grey[300],
              color: forecast.confidenceScore > 0.8 ? Colors.green : 
                     forecast.confidenceScore > 0.6
                      ? Theme.of(context).colorScheme.primary
                      : Colors.red,
              strokeWidth: 6,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandPredictionsSection(DemandForecastingData forecast, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: theme.primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Demand Predictions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: _buildDemandChart(forecast.dailyPredictions, theme),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPredictionCard(
                'Today',
                forecast.hourlyPredictions.take(24).fold<int>(0, (sum, p) => sum + p.predictedOrders),
                forecast.hourlyPredictions.take(24).fold<double>(0, (sum, p) => sum + p.predictedRevenue),
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPredictionCard(
                'This Week',
                forecast.weeklyPredictions.isNotEmpty ? forecast.weeklyPredictions.first.predictedOrders : 0,
                forecast.weeklyPredictions.isNotEmpty ? forecast.weeklyPredictions.first.predictedRevenue : 0.0,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemandChart(List<DemandPrediction> predictions, ThemeData theme) {
    if (predictions.isEmpty) {
      return const Center(
        child: Text('No prediction data available'),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'AI Demand Prediction Chart\n(Chart implementation pending)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionCard(String title, int orders, double revenue, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '$orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text('orders', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text(
              '\$${revenue.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakHoursSection(PeakHoursAnalysis peakHours, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule, color: theme.primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Peak Hours Analysis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Peak Hours',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...peakHours.dailyPeaks.map((peak) => ListTile(
                  leading: Icon(Icons.schedule, color: theme.primaryColor),
                  title: Text('${peak.hour}:00 - ${peak.hour + 1}:00'),
                  subtitle: Text('${peak.averageOrders} orders avg'),
                  trailing: Text(
                    '\$${peak.averageRevenue.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),
                const Divider(),
                const Text(
                  'Staffing Recommendations',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estimated monthly savings: \$${peakHours.staffing.estimatedCostSaving.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...peakHours.staffing.dailyStaffing.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text('${entry.value} staff', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(List<BusinessRecommendation> recommendations, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: theme.primaryColor),
            const SizedBox(width: 8),
            const Text(
              'AI Recommendations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recommendations.take(5).map((rec) => Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRecommendationColor(rec.type).withOpacity(0.1),
              child: Icon(
                _getRecommendationIcon(rec.type),
                color: _getRecommendationColor(rec.type),
                size: 20,
              ),
            ),
            title: Text(
              rec.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(rec.description),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${rec.priority.toStringAsFixed(1)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'priority',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
            onTap: () => _showRecommendationDetails(rec),
          ),
        )),
      ],
    );
  }

  Widget _buildSeasonalTrendsSection(SeasonalTrends trends, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.nature_outlined, color: theme.primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Seasonal Trends',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...trends.patterns.map((pattern) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pattern.season,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${pattern.demandChange > 0 ? '+' : ''}${pattern.demandChange.toStringAsFixed(1)}% demand',
                              style: TextStyle(
                                color: pattern.demandChange > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        pattern.trend == 'increasing' ? Icons.trending_up : 
                        pattern.trend == 'decreasing' ? Icons.trending_down : Icons.trending_flat,
                        color: pattern.trend == 'increasing' ? Colors.green : 
                               pattern.trend == 'decreasing'
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                )),
                const Divider(),
                const Text(
                  'Menu Optimization Suggestions',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...trends.menuSuggestions.take(3).map((suggestion) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.restaurant_menu, size: 20),
                  title: Text(suggestion.itemName),
                  subtitle: Text(suggestion.suggestion),
                  trailing: Text(
                    '+${suggestion.potentialImpact.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getRecommendationColor(String type) {
    switch (type) {
      case 'staffing': return Colors.blue;
      case 'menu': return Colors.green;
      case 'marketing':
        return const Color(0xFF32CD32);
      case 'pricing': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getRecommendationIcon(String type) {
    switch (type) {
      case 'staffing': return Icons.people;
      case 'menu': return Icons.restaurant_menu;
      case 'marketing': return Icons.campaign;
      case 'pricing': return Icons.attach_money;
      default: return Icons.lightbulb_outline;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showRecommendationDetails(BusinessRecommendation rec) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(rec.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rec.description),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.priority_high, color: _getRecommendationColor(rec.type)),
                const SizedBox(width: 8),
                Text('Priority: ${rec.priority.toStringAsFixed(1)}/10'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.green),
                const SizedBox(width: 8),
                Text('Impact: +${rec.estimatedImpact.toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Action Required:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(rec.actionRequired),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement action taking
            },
            child: const Text('Take Action'),
          ),
        ],
      ),
    );
  }

  // Material You time range chip builder
  Widget _buildMaterialTimeRangeChip(String label, int index) {
    final isSelected = _selectedTimeRange == index;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedTimeRange = index);
      },
      selectedColor: context.colorScheme.primaryContainer,
      checkmarkColor: context.colorScheme.onPrimaryContainer,
      backgroundColor: context.colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? context.colorScheme.primary
            : context.colorScheme.outline,
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? context.colorScheme.onPrimaryContainer
            : context.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
