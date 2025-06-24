import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/business.dart';
import '../l10n/app_localizations.dart';

class AnalyticsData {
  final double totalSales;
  final int totalOrders;
  final double averageOrderValue;
  final List<TopSellingItem> topSellingItems;
  final Map<OrderStatus, int> ordersByStatus;

  AnalyticsData({
    required this.totalSales,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.topSellingItems,
    required this.ordersByStatus,
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

class AnalyticsPage extends StatelessWidget {
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

  String get businessName => business.name;

  AnalyticsData _generateAnalyticsData(AppLocalizations loc) {
    // Placeholder: In real app, calculate from orders
    double totalSales = orders.fold(0.0, (sum, o) => sum + (o.totalAmount));
    double averageOrderValue =
        orders.isEmpty ? 0.0 : totalSales / orders.length;
    return AnalyticsData(
      totalSales: totalSales,
      totalOrders: orders.length,
      averageOrderValue: averageOrderValue,
      topSellingItems: [
        TopSellingItem(
            itemName: loc.sampleItem, soldQuantity: 10, revenue: 100),
      ],
      ordersByStatus: {
        for (var status in OrderStatus.values)
          status: orders.where((o) => o.status == status).length
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final analytics = _generateAnalyticsData(loc);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.analytics),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              businessName,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetricCard(
                    context,
                    loc.totalSales,
                    analytics.totalSales.toStringAsFixed(2),
                    Icons.attach_money,
                    Colors.green),
                _buildMetricCard(
                    context,
                    loc.totalOrders,
                    analytics.totalOrders.toString(),
                    Icons.shopping_cart,
                    Colors.blue),
                _buildMetricCard(
                    context,
                    loc.averageOrderValue,
                    analytics.averageOrderValue.toStringAsFixed(2),
                    Icons.analytics,
                    Colors.orange),
              ],
            ),
            const SizedBox(height: 24),
            Text(loc.topSellingItems,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            ...analytics.topSellingItems.map((item) => ListTile(
                  title: Text(item.itemName),
                  subtitle: Text(loc.itemSoldQuantity(item.soldQuantity)),
                  trailing:
                      Text(loc.itemRevenue(item.revenue.toStringAsFixed(2))),
                )),
            const SizedBox(height: 24),
            Text(loc.ordersByStatus,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            ...analytics.ordersByStatus.entries.map((entry) => ListTile(
                  title: Text(_localizedOrderStatus(loc, entry.key)),
                  trailing: Text(entry.value.toString()),
                )),
          ],
        ),
      ),
    );
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

  Widget _buildMetricCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
