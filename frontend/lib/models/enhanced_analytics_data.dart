import '../models/order.dart';

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

class RevenueBreakdown {
  final String period;
  final double amount;
  final double percentage;
  final String color;

  RevenueBreakdown({
    required this.period,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class PerformanceMetrics {
  final double averagePreparationTime;
  final double successRate;
  final double customerSatisfaction;
  final int repeatCustomers;
  final double peakHourRevenue;

  PerformanceMetrics({
    required this.averagePreparationTime,
    required this.successRate,
    required this.customerSatisfaction,
    required this.repeatCustomers,
    required this.peakHourRevenue,
  });
}
