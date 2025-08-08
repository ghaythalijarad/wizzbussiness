import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/enhanced_analytics_data.dart';

class DemandForecastingService {
  static const String baseUrl = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

  /// Fetch comprehensive demand forecasting data for a business
  static Future<DemandForecastingData?> getDemandForecast({
    required String businessId,
    String timeframe = '7d', // '1d', '7d', '30d'
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/demand-forecast/$businessId?timeframe=$timeframe'),
        headers: {
          'Content-Type': 'application/json',
          // TODO: Add authorization headers when implementing auth
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return DemandForecastingData.fromJson(data);
      } else {
        print('Error fetching demand forecast: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception in getDemandForecast: $e');
      return null;
    }
  }

  /// Fetch peak hours analysis specifically
  static Future<PeakHoursAnalysis?> getPeakHoursAnalysis({
    required String businessId,
    String timeframe = '30d',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/peak-hours/$businessId?timeframe=$timeframe'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return PeakHoursAnalysis.fromJson(data);
      } else {
        print('Error fetching peak hours analysis: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception in getPeakHoursAnalysis: $e');
      return null;
    }
  }

  /// Fetch seasonal trends analysis
  static Future<SeasonalTrends?> getSeasonalTrends({
    required String businessId,
    String timeframe = '365d',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/seasonal-trends/$businessId?timeframe=$timeframe'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return SeasonalTrends.fromJson(data);
      } else {
        print('Error fetching seasonal trends: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception in getSeasonalTrends: $e');
      return null;
    }
  }

  /// Generate mock demand forecasting data for development/testing
  static DemandForecastingData generateMockData() {
    final now = DateTime.now();
    
    return DemandForecastingData(
      hourlyPredictions: List.generate(24, (hour) {
        return DemandPrediction(
          timestamp: now.add(Duration(hours: hour)),
          predictedOrders: 15 + (hour % 3 == 0 ? 10 : 0), // Mock peak hours
          predictedRevenue: (15 + (hour % 3 == 0 ? 10 : 0)) * 25.0,
          confidenceLevel: 0.85 + (0.1 * (hour % 2)),
          timeframe: 'hour',
        );
      }),
      dailyPredictions: List.generate(7, (day) {
        return DemandPrediction(
          timestamp: now.add(Duration(days: day)),
          predictedOrders: 180 + (day % 2 == 0 ? 50 : -20),
          predictedRevenue: (180 + (day % 2 == 0 ? 50 : -20)) * 25.0,
          confidenceLevel: 0.78 + (0.05 * day),
          timeframe: 'day',
        );
      }),
      weeklyPredictions: List.generate(4, (week) {
        return DemandPrediction(
          timestamp: now.add(Duration(days: week * 7)),
          predictedOrders: 1200 + (week % 2 == 0 ? 200 : -100),
          predictedRevenue: (1200 + (week % 2 == 0 ? 200 : -100)) * 25.0,
          confidenceLevel: 0.72 + (0.03 * week),
          timeframe: 'week',
        );
      }),
      peakHours: PeakHoursAnalysis(
        dailyPeaks: [
          PeakHour(hour: 12, dayOfWeek: 'All', averageOrders: 25, averageRevenue: 625.0, intensity: 0.9),
          PeakHour(hour: 19, dayOfWeek: 'All', averageOrders: 30, averageRevenue: 750.0, intensity: 1.0),
        ],
        weeklyPeaks: [
          PeakHour(hour: 12, dayOfWeek: 'Friday', averageOrders: 35, averageRevenue: 875.0, intensity: 1.0),
          PeakHour(hour: 19, dayOfWeek: 'Saturday', averageOrders: 40, averageRevenue: 1000.0, intensity: 1.0),
        ],
        staffing: StaffingRecommendations(
          dailyStaffing: {
            'Monday': 3,
            'Tuesday': 3,
            'Wednesday': 3,
            'Thursday': 4,
            'Friday': 5,
            'Saturday': 6,
            'Sunday': 4,
          },
          shifts: {
            'peak': [
              ShiftRecommendation(
                startTime: '11:00',
                endTime: '14:00',
                staffCount: 4,
                reason: 'Lunch rush preparation',
              ),
              ShiftRecommendation(
                startTime: '18:00',
                endTime: '21:00',
                staffCount: 5,
                reason: 'Dinner peak hours',
              ),
            ],
          },
          estimatedCostSaving: 1250.0,
        ),
      ),
      seasonalTrends: SeasonalTrends(
        patterns: [
          SeasonalPattern(
            season: 'Winter',
            demandChange: 15.0,
            topItems: ['Hot Soup', 'Coffee', 'Hot Sandwich'],
            trend: 'increasing',
          ),
          SeasonalPattern(
            season: 'Summer',
            demandChange: -8.0,
            topItems: ['Iced Drinks', 'Salads', 'Cold Sandwiches'],
            trend: 'decreasing',
          ),
        ],
        menuSuggestions: [
          MenuOptimizationSuggestion(
            itemName: 'Seasonal Soup',
            suggestion: 'Add winter specials during cold months',
            potentialImpact: 12.5,
            reasoning: 'Historical data shows 40% increase in soup sales during winter',
          ),
          MenuOptimizationSuggestion(
            itemName: 'Summer Smoothies',
            suggestion: 'Expand smoothie menu for summer season',
            potentialImpact: 8.7,
            reasoning: 'Cold beverages show 25% higher demand in hot weather',
          ),
        ],
        seasonalMultipliers: {
          'Spring': 1.05,
          'Summer': 0.92,
          'Fall': 1.08,
          'Winter': 1.15,
        },
      ),
      recommendations: [
        BusinessRecommendation(
          type: 'staffing',
          title: 'Optimize Weekend Staffing',
          description: 'Increase staff by 2 people during weekend dinner rush',
          priority: 8.5,
          estimatedImpact: 15.0,
          actionRequired: 'Schedule additional staff for Friday-Sunday 6-9 PM',
        ),
        BusinessRecommendation(
          type: 'menu',
          title: 'Seasonal Menu Update',
          description: 'Add winter comfort food items to boost cold weather sales',
          priority: 7.2,
          estimatedImpact: 12.0,
          actionRequired: 'Design and test 3-4 winter special dishes',
        ),
        BusinessRecommendation(
          type: 'marketing',
          title: 'Lunch Hour Promotion',
          description: 'Target office workers with quick lunch deals during 11:30-1:30',
          priority: 6.8,
          estimatedImpact: 9.5,
          actionRequired: 'Create express lunch menu and promote on social media',
        ),
      ],
      confidenceScore: 0.83,
      lastUpdated: now,
    );
  }
}
