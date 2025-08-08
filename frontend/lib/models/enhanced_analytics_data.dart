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
  final DemandForecastingData? demandForecast; // AI/ML Demand Forecasting

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
    this.demandForecast,
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

// AI/ML Demand Forecasting Data Models
class DemandForecastingData {
  final List<DemandPrediction> hourlyPredictions;
  final List<DemandPrediction> dailyPredictions;
  final List<DemandPrediction> weeklyPredictions;
  final PeakHoursAnalysis peakHours;
  final SeasonalTrends seasonalTrends;
  final List<BusinessRecommendation> recommendations;
  final double confidenceScore;
  final DateTime lastUpdated;

  DemandForecastingData({
    required this.hourlyPredictions,
    required this.dailyPredictions,
    required this.weeklyPredictions,
    required this.peakHours,
    required this.seasonalTrends,
    required this.recommendations,
    required this.confidenceScore,
    required this.lastUpdated,
  });

  factory DemandForecastingData.fromJson(Map<String, dynamic> json) {
    return DemandForecastingData(
      hourlyPredictions: (json['hourlyPredictions'] as List)
          .map((item) => DemandPrediction.fromJson(item))
          .toList(),
      dailyPredictions: (json['dailyPredictions'] as List)
          .map((item) => DemandPrediction.fromJson(item))
          .toList(),
      weeklyPredictions: (json['weeklyPredictions'] as List)
          .map((item) => DemandPrediction.fromJson(item))
          .toList(),
      peakHours: PeakHoursAnalysis.fromJson(json['peakHours']),
      seasonalTrends: SeasonalTrends.fromJson(json['seasonalTrends']),
      recommendations: (json['recommendations'] as List)
          .map((item) => BusinessRecommendation.fromJson(item))
          .toList(),
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}

class DemandPrediction {
  final DateTime timestamp;
  final int predictedOrders;
  final double predictedRevenue;
  final double confidenceLevel;
  final String timeframe; // 'hour', 'day', 'week'

  DemandPrediction({
    required this.timestamp,
    required this.predictedOrders,
    required this.predictedRevenue,
    required this.confidenceLevel,
    required this.timeframe,
  });

  factory DemandPrediction.fromJson(Map<String, dynamic> json) {
    return DemandPrediction(
      timestamp: DateTime.parse(json['timestamp']),
      predictedOrders: json['predictedOrders'] as int,
      predictedRevenue: (json['predictedRevenue'] as num).toDouble(),
      confidenceLevel: (json['confidenceLevel'] as num).toDouble(),
      timeframe: json['timeframe'] as String,
    );
  }
}

class PeakHoursAnalysis {
  final List<PeakHour> dailyPeaks;
  final List<PeakHour> weeklyPeaks;
  final StaffingRecommendations staffing;

  PeakHoursAnalysis({
    required this.dailyPeaks,
    required this.weeklyPeaks,
    required this.staffing,
  });

  factory PeakHoursAnalysis.fromJson(Map<String, dynamic> json) {
    return PeakHoursAnalysis(
      dailyPeaks: (json['dailyPeaks'] as List)
          .map((item) => PeakHour.fromJson(item))
          .toList(),
      weeklyPeaks: (json['weeklyPeaks'] as List)
          .map((item) => PeakHour.fromJson(item))
          .toList(),
      staffing: StaffingRecommendations.fromJson(json['staffing']),
    );
  }
}

class PeakHour {
  final int hour;
  final String dayOfWeek;
  final int averageOrders;
  final double averageRevenue;
  final double intensity; // 0-1 scale

  PeakHour({
    required this.hour,
    required this.dayOfWeek,
    required this.averageOrders,
    required this.averageRevenue,
    required this.intensity,
  });

  factory PeakHour.fromJson(Map<String, dynamic> json) {
    return PeakHour(
      hour: json['hour'] as int,
      dayOfWeek: json['dayOfWeek'] as String,
      averageOrders: json['averageOrders'] as int,
      averageRevenue: (json['averageRevenue'] as num).toDouble(),
      intensity: (json['intensity'] as num).toDouble(),
    );
  }
}

class StaffingRecommendations {
  final Map<String, int> dailyStaffing; // day -> staff count
  final Map<String, List<ShiftRecommendation>> shifts;
  final double estimatedCostSaving;

  StaffingRecommendations({
    required this.dailyStaffing,
    required this.shifts,
    required this.estimatedCostSaving,
  });

  factory StaffingRecommendations.fromJson(Map<String, dynamic> json) {
    return StaffingRecommendations(
      dailyStaffing: Map<String, int>.from(json['dailyStaffing']),
      shifts: (json['shifts'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List).map((item) => ShiftRecommendation.fromJson(item)).toList(),
        ),
      ),
      estimatedCostSaving: (json['estimatedCostSaving'] as num).toDouble(),
    );
  }
}

class ShiftRecommendation {
  final String startTime;
  final String endTime;
  final int staffCount;
  final String reason;

  ShiftRecommendation({
    required this.startTime,
    required this.endTime,
    required this.staffCount,
    required this.reason,
  });

  factory ShiftRecommendation.fromJson(Map<String, dynamic> json) {
    return ShiftRecommendation(
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      staffCount: json['staffCount'] as int,
      reason: json['reason'] as String,
    );
  }
}

class SeasonalTrends {
  final List<SeasonalPattern> patterns;
  final List<MenuOptimizationSuggestion> menuSuggestions;
  final Map<String, double> seasonalMultipliers;

  SeasonalTrends({
    required this.patterns,
    required this.menuSuggestions,
    required this.seasonalMultipliers,
  });

  factory SeasonalTrends.fromJson(Map<String, dynamic> json) {
    return SeasonalTrends(
      patterns: (json['patterns'] as List)
          .map((item) => SeasonalPattern.fromJson(item))
          .toList(),
      menuSuggestions: (json['menuSuggestions'] as List)
          .map((item) => MenuOptimizationSuggestion.fromJson(item))
          .toList(),
      seasonalMultipliers: Map<String, double>.from(json['seasonalMultipliers']),
    );
  }
}

class SeasonalPattern {
  final String season;
  final double demandChange; // percentage change
  final List<String> topItems;
  final String trend; // 'increasing', 'decreasing', 'stable'

  SeasonalPattern({
    required this.season,
    required this.demandChange,
    required this.topItems,
    required this.trend,
  });

  factory SeasonalPattern.fromJson(Map<String, dynamic> json) {
    return SeasonalPattern(
      season: json['season'] as String,
      demandChange: (json['demandChange'] as num).toDouble(),
      topItems: List<String>.from(json['topItems']),
      trend: json['trend'] as String,
    );
  }
}

class MenuOptimizationSuggestion {
  final String itemName;
  final String suggestion;
  final double potentialImpact; // percentage revenue impact
  final String reasoning;

  MenuOptimizationSuggestion({
    required this.itemName,
    required this.suggestion,
    required this.potentialImpact,
    required this.reasoning,
  });

  factory MenuOptimizationSuggestion.fromJson(Map<String, dynamic> json) {
    return MenuOptimizationSuggestion(
      itemName: json['itemName'] as String,
      suggestion: json['suggestion'] as String,
      potentialImpact: (json['potentialImpact'] as num).toDouble(),
      reasoning: json['reasoning'] as String,
    );
  }
}

class BusinessRecommendation {
  final String type; // 'staffing', 'marketing', 'menu', 'pricing'
  final String title;
  final String description;
  final double priority; // 1-10 scale
  final double estimatedImpact; // percentage or dollar amount
  final String actionRequired;

  BusinessRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.estimatedImpact,
    required this.actionRequired,
  });

  factory BusinessRecommendation.fromJson(Map<String, dynamic> json) {
    return BusinessRecommendation(
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: (json['priority'] as num).toDouble(),
      estimatedImpact: (json['estimatedImpact'] as num).toDouble(),
      actionRequired: json['actionRequired'] as String,
    );
  }
}
