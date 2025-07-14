import 'dart:async';

/// Service to manage order timers for tracking order processing time
class OrderTimerService {
  static final Map<String, DateTime> _orderStartTimes = {};
  static const int maxProcessingTimeMinutes = 30; // 30 minutes max processing time

  /// Initialize timer for a new order
  static void startTimer(String orderId) {
    _orderStartTimes[orderId] = DateTime.now();
  }

  /// Get remaining seconds for an order (returns 0 if expired or not found)
  static int getRemainingSeconds(String orderId) {
    final startTime = _orderStartTimes[orderId];
    if (startTime == null) {
      return 0;
    }

    final elapsed = DateTime.now().difference(startTime);
    final maxDuration = Duration(minutes: maxProcessingTimeMinutes);
    final remaining = maxDuration - elapsed;

    return remaining.inSeconds > 0 ? remaining.inSeconds : 0;
  }

  /// Get elapsed time for an order in seconds
  static int getElapsedSeconds(String orderId) {
    final startTime = _orderStartTimes[orderId];
    if (startTime == null) {
      return 0;
    }

    return DateTime.now().difference(startTime).inSeconds;
  }

  /// Remove timer for completed/cancelled orders
  static void removeTimer(String orderId) {
    _orderStartTimes.remove(orderId);
  }

  /// Clear all timers
  static void clearAllTimers() {
    _orderStartTimes.clear();
  }

  /// Check if an order timer exists
  static bool hasTimer(String orderId) {
    return _orderStartTimes.containsKey(orderId);
  }

  /// Get formatted remaining time string (MM:SS format)
  static String getFormattedRemainingTime(String orderId) {
    final remainingSeconds = getRemainingSeconds(orderId);
    if (remainingSeconds <= 0) {
      return "00:00";
    }

    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  /// Check if an order has expired its processing time
  static bool isOrderExpired(String orderId) {
    return getRemainingSeconds(orderId) <= 0;
  }
}
