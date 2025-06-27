import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/order.dart';
import '../models/business.dart';
import '../l10n/app_localizations.dart';
import 'dart:math' as math;

class AnalyticsData {
  final double totalRevenue;
  final double dailyRevenue;
  final double weeklyRevenue;
  final double monthlyRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final List<TopSellingItem> topSellingItems;
  final Map<OrderStatus, int> ordersByStatus;
  final List<DailyRevenue> revenueChart;
  final double growthRate;
  final int customersServed;
  final double cancellationRate;
  final double averagePreparationTime;

  AnalyticsData({
    required this.totalRevenue,
    required this.dailyRevenue,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.topSellingItems,
    required this.ordersByStatus,
    required this.revenueChart,
    required this.growthRate,
    required this.customersServed,
    required this.cancellationRate,
    required this.averagePreparationTime,
  });
}

class TopSellingItem {
  final String itemName;
  final int soldQuantity;
  final double revenue;

  TopSellingItem({
    required this.itemName,
    required this.soldQuantity,
    required this.revenue,
  });
}

class DailyRevenue {
  final DateTime date;
  final double revenue;

  DailyRevenue({
    required this.date,
    required this.revenue,
  });
}

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get businessName => widget.business.name;

  AnalyticsData _generateAnalyticsData(AppLocalizations loc) {
    // Calculate real analytics from orders
    double totalRevenue = widget.orders.fold(0.0, (sum, o) => sum + o.totalAmount);
    double dailyRevenue = widget.orders
        .where((o) => o.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 1))))
        .fold(0.0, (sum, o) => sum + o.totalAmount);
    double weeklyRevenue = widget.orders
        .where((o) => o.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .fold(0.0, (sum, o) => sum + o.totalAmount);
    double monthlyRevenue = widget.orders
        .where((o) => o.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .fold(0.0, (sum, o) => sum + o.totalAmount);

    double averageOrderValue = widget.orders.isEmpty ? 0.0 : totalRevenue / widget.orders.length;
    
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
      topSellingItems: [
        TopSellingItem(itemName: loc.sampleItem, soldQuantity: 25, revenue: 750),
        TopSellingItem(itemName: "Special Dish", soldQuantity: 18, revenue: 540),
        TopSellingItem(itemName: "Popular Item", soldQuantity: 12, revenue: 360),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final analytics = _generateAnalyticsData(loc);
    final theme = Theme.of(context);
    
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  loc.analytics,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  ),
                ),
              ),
            ),
          ];
        },
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
                  _buildTimeRangeButton("Today", 0),
                  _buildTimeRangeButton("Week", 1),
                  _buildTimeRangeButton("Month", 2),
                  _buildTimeRangeButton("Year", 3),
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
              tabs: const [
                Tab(text: "Overview"),
                Tab(text: "Revenue"),
                Tab(text: "Performance"),
              ],
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(analytics, loc, theme),
                  _buildRevenueTab(analytics, loc, theme),
                  _buildPerformanceTab(analytics, loc, theme),
                ],
              ),
            ),
          ],
        ),
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
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
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

  Widget _buildOverviewTab(AnalyticsData analytics, AppLocalizations loc, ThemeData theme) {
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
                title: "Total Revenue",
                value: "\$${analytics.totalRevenue.toStringAsFixed(2)}",
                icon: Icons.monetization_on,
                color: const Color(0xFF4CAF50),
                growth: "+${analytics.growthRate}%",
              ),
              _buildRevenueCard(
                title: "Today's Revenue",
                value: "\$${analytics.dailyRevenue.toStringAsFixed(2)}",
                icon: Icons.today,
                color: const Color(0xFF2196F3),
                growth: "+8.2%",
              ),
              _buildRevenueCard(
                title: "Total Orders",
                value: "${analytics.totalOrders}",
                icon: Icons.shopping_cart,
                color: const Color(0xFFFF9800),
                growth: "+15.1%",
              ),
              _buildRevenueCard(
                title: "Avg Order Value",
                value: "\$${analytics.averageOrderValue.toStringAsFixed(2)}",
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
        ],
      ),
    );
  }

  Widget _buildRevenueTab(AnalyticsData analytics, AppLocalizations loc, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Revenue Chart Card
          Card(
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
                        "Revenue Trend",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                  '\$${value.toInt()}',
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final date = analytics.revenueChart[value.toInt() % analytics.revenueChart.length].date;
                                return Text(
                                  '${date.day}/${date.month}',
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: analytics.revenueChart.asMap().entries.map((entry) {
                              return FlSpot(entry.key.toDouble(), entry.value.revenue);
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

  Widget _buildPerformanceTab(AnalyticsData analytics, AppLocalizations loc, ThemeData theme) {
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
                Icon(icon, color: Colors.white, size: 28),                  Container(
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
              "Quick Stats",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatItem(
                    "Customers Served",
                    "${analytics.customersServed}",
                    Icons.people,
                    const Color(0xFF4CAF50),
                  ),
                ),
                Expanded(
                  child: _buildQuickStatItem(
                    "Cancellation Rate",
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

  Widget _buildQuickStatItem(String title, String value, IconData icon, Color color) {
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

  Widget _buildTopSellingItemsCard(AnalyticsData analytics, AppLocalizations loc) {
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
                          "\$${item.revenue.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        Text(
                          "Revenue",
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

  Widget _buildRevenueBreakdownCard(AnalyticsData analytics, AppLocalizations loc) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Revenue Breakdown",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildRevenueBreakdownItem("Daily Revenue", analytics.dailyRevenue, const Color(0xFF2196F3)),
            _buildRevenueBreakdownItem("Weekly Revenue", analytics.weeklyRevenue, const Color(0xFF4CAF50)),
            _buildRevenueBreakdownItem("Monthly Revenue", analytics.monthlyRevenue, const Color(0xFFFF9800)),
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
            "\$${amount.toStringAsFixed(2)}",
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

  Widget _buildPerformanceMetricsCard(AnalyticsData analytics, AppLocalizations loc) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Performance Metrics",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceMetric(
                    "Avg Prep Time",
                    "${analytics.averagePreparationTime.toStringAsFixed(1)} min",
                    Icons.timer,
                    const Color(0xFF2196F3),
                  ),
                ),
                Expanded(
                  child: _buildPerformanceMetric(
                    "Success Rate",
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

  Widget _buildPerformanceMetric(String title, String value, IconData icon, Color color) {
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

  List<PieChartSectionData> _buildPieChartSections(Map<OrderStatus, int> ordersByStatus) {
    final total = ordersByStatus.values.fold<int>(0, (sum, count) => sum + count);
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
        return const Color(0xFF9C27B0);
      case OrderStatus.ready:
        return const Color(0xFF4CAF50);
      case OrderStatus.pickedUp:
        return const Color(0xFF00BCD4);
      case OrderStatus.cancelled:
        return const Color(0xFFF44336);
      case OrderStatus.returned:
        return const Color(0xFF795548);
      case OrderStatus.expired:
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
      case OrderStatus.pickedUp:
        return loc.orderStatusPickedUp;
      case OrderStatus.cancelled:
        return loc.orderStatusCancelled;
      case OrderStatus.returned:
        return loc.orderStatusReturned;
      case OrderStatus.expired:
        return loc.orderStatusExpired;
    }
  }
}
