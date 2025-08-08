import '../models/order.dart';

class AnalyticsData {
  final double totalRevenue;
  final double dailyRevenue;
  final double weeklyRevenue;
  final double monthlyRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final List<TopSellingItem> topSellingItems;
  final List<LeastOrderedItem> leastOrderedItems;
  final List<ReviewData> recentReviews;
  final Map<OrderStatus, int> ordersByStatus;
  final List<DailyRevenue> revenueChart;
  final double growthRate;
  final int customersServed;
  final double cancellationRate;
  final double averagePreparationTime;
  final double averageRating;
  final int totalReviews;

  AnalyticsData({
    required this.totalRevenue,
    required this.dailyRevenue,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.topSellingItems,
    required this.leastOrderedItems,
    required this.recentReviews,
    required this.ordersByStatus,
    required this.revenueChart,
    required this.growthRate,
    required this.customersServed,
    required this.cancellationRate,
    required this.averagePreparationTime,
    required this.averageRating,
    required this.totalReviews,
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

class LeastOrderedItem {
  final String itemName;
  final int soldQuantity;
  final double revenue;

  LeastOrderedItem({
    required this.itemName,
    required this.soldQuantity,
    required this.revenue,
  });
}

class ReviewData {
  final String customerName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String orderId;

  ReviewData({
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.orderId,
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
