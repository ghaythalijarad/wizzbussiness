import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/order.dart';
import '../models/business.dart';
import '../l10n/app_localizations.dart';
import 'dart:math' as math;
import '../models/enhanced_analytics_data.dart';

class AnalyticsPage extends StatefulWidget {
  final Business business;
  final List<Order> orders;
  final VoidCallback? onNavigateToOrders;
  final Function(String, OrderStatus)? onOrderUpdated;

  const AnalyticsPage({
    Key? key,
    required this.business,
    required this.orders,
    this.onNavigateToOrders,
    this.onOrderUpdated,
  }) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTimeRange = 0; // 0: Today, 1: Week, 2: Month, 3: Year

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final analytics = _generateAnalyticsData(loc);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Time Range Selector
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTimeRangeButton(loc.today, 0),
                _buildTimeRangeButton(loc.week, 1),
                _buildTimeRangeButton(loc.month, 2),
                _buildTimeRangeButton(loc.year, 3),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(String label, int index) {
    final isSelected = _selectedTimeRange == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTimeRange = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
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
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()} IQD',
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final date = analytics
                                    .revenueChart[value.toInt() %
                                        analytics.revenueChart.length]
                                    .date;
                                return Text(
                                  '${date.day}/${date.month}',
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: analytics.revenueChart
                                .asMap()
                                .entries
                                .map((entry) {
                              return FlSpot(
                                  entry.key.toDouble(), entry.value.revenue);
                            }).toList(),
                            isCurved: true,
                            gradient: LinearGradient(
                              colors: [
                                theme.primaryColor,
                                theme.primaryColor.withOpacity(0.3),
                              ],
                            ),
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  theme.primaryColor.withOpacity(0.3),
                                  theme.primaryColor.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                        ],
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
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      ),
    );
  }

  Widget _buildQuickStatsCard(AnalyticsData analytics, AppLocalizations loc) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.quickStats,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
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
                    const Color(0xFF4CAF50),
                  ),
                ),
                Expanded(
                  child: _buildQuickStatItem(
                    loc.cancellationRate,
                    "${analytics.cancellationRate}%",
                    Icons.cancel,
                    const Color(0xFFF44336),
                  ),
                ),
              ],
            ),
          ],
        ),
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
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellingItemsCard(
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
              loc.topSellingItems,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...analytics.topSellingItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            loc.itemSoldQuantity(item.soldQuantity),
                            style: TextStyle(
                              color: Colors.grey[600],
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF4CAF50),
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

  Widget _buildRevenueBreakdownCard(
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
              loc.revenueBreakdown,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            _buildRevenueBreakdownItem(loc.dailyRevenue, analytics.dailyRevenue,
                const Color(0xFF2196F3)),
            _buildRevenueBreakdownItem(loc.weeklyRevenue,
                analytics.weeklyRevenue, const Color(0xFF4CAF50)),
            _buildRevenueBreakdownItem(loc.monthlyRevenue,
                analytics.monthlyRevenue, const Color(0xFFFF9800)),
          ],
        ),
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.performanceMetrics,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
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
                    const Color(0xFF2196F3),
                  ),
                ),
                Expanded(
                  child: _buildPerformanceMetric(
                    loc.successRate,
                    "${(100 - analytics.cancellationRate).toStringAsFixed(1)}%",
                    Icons.check_circle,
                    const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ],
        ),
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
              color: Colors.grey[600],
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(analytics.ordersByStatus),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
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

  List<PieChartSectionData> _buildPieChartSections(
      Map<OrderStatus, int> ordersByStatus) {
    final total =
        ordersByStatus.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) return [];

    return ordersByStatus.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: _getStatusColor(entry.key),
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFFF9800);
      case OrderStatus.confirmed:
        return const Color(0xFF2196F3);
      case OrderStatus.preparing:
        return const Color(0xFF4169E1);
      case OrderStatus.ready:
        return const Color(0xFF4CAF50);
      case OrderStatus.onTheWay:
        return const Color(0xFF9932CC);
      case OrderStatus.delivered:
        return const Color(0xFF228B22);
      case OrderStatus.cancelled:
        return const Color(0xFFF44336);
      case OrderStatus.returned:
        return const Color(0xFF795548);
      case OrderStatus.expired:
        return const Color(0xFF607D8B);
      default:
        return const Color(0xFF607D8B);
    }
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
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange[400],
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
                              color: Colors.orange[700],
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.orange,
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
}
