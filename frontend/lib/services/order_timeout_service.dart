import 'dart:async';
import 'dart:developer' as developer;
import '../models/order.dart';
import 'audio_notification_service.dart';
import 'order_service.dart';

class OrderTimeoutService {
  static final OrderTimeoutService _instance = OrderTimeoutService._internal();
  factory OrderTimeoutService() => _instance;
  OrderTimeoutService._internal();

  Timer? _monitoringTimer;
  final Set<String> _processedAlerts = {};
  final Map<String, OrderTimeoutStatus> _lastTimeoutStatus = {};

  final AudioNotificationService _audioService = AudioNotificationService();
  final OrderService _orderService = OrderService();

  // Callback for when an order is auto-rejected
  Function()? onOrderAutoRejected;

  /// Start monitoring orders for timeout alerts
  void startMonitoring(List<Order> orders) {
    developer.log('⏰ Starting timeout monitoring for ${orders.length} orders');

    // Check immediately
    _checkTimeouts(orders);

    // Start periodic checking every 10 seconds
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkTimeouts(orders),
    );
  }

  /// Stop monitoring
  void stopMonitoring() {
    developer.log('⏰ Stopping timeout monitoring');
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _processedAlerts.clear();
    _lastTimeoutStatus.clear();
  }

  /// Check all orders for timeout conditions
  void _checkTimeouts(List<Order> orders) {
    final pendingOrders =
        orders.where((order) => order.status == OrderStatus.pending).toList();

    for (final order in pendingOrders) {
      _checkOrderTimeout(order);
    }
  }

  /// Check individual order for timeout
  void _checkOrderTimeout(Order order) {
    final currentStatus = order.getTimeoutStatus();
    final previousStatus = _lastTimeoutStatus[order.id];

    // Only process if status has changed to prevent duplicate alerts
    if (currentStatus != previousStatus) {
      _lastTimeoutStatus[order.id] = currentStatus;

      switch (currentStatus) {
        case OrderTimeoutStatus.firstAlert:
          _handleFirstAlert(order);
          break;
        case OrderTimeoutStatus.urgentAlert:
          _handleUrgentAlert(order);
          break;
        case OrderTimeoutStatus.autoReject:
          _handleAutoReject(order);
          break;
        case OrderTimeoutStatus.normal:
        case OrderTimeoutStatus.notApplicable:
          // No action needed
          break;
      }
    }
  }

  /// Handle first alert (2 minutes)
  void _handleFirstAlert(Order order) {
    final alertKey = '${order.id}_first';
    if (_processedAlerts.contains(alertKey)) return;

    developer.log('⏰ First alert for order ${order.id}');
    _processedAlerts.add(alertKey);

    // Play gentle reminder sound
    _audioService.playGentleReminder();

    // Log timeout event
    _logTimeoutEvent(order, 'firstAlert');
  }

  /// Handle urgent alert (5 minutes)
  void _handleUrgentAlert(Order order) {
    final alertKey = '${order.id}_urgent';
    if (_processedAlerts.contains(alertKey)) return;

    developer.log('⏰ Urgent alert for order ${order.id}');
    _processedAlerts.add(alertKey);

    // Play urgent alert sound
    _audioService.playUrgentAlert();

    // Log timeout event
    _logTimeoutEvent(order, 'urgentAlert');
  }

  /// Handle auto-reject (8 minutes)
  void _handleAutoReject(Order order) {
    final alertKey = '${order.id}_reject';
    if (_processedAlerts.contains(alertKey)) return;

    developer.log('⏰ Auto-rejecting order ${order.id}');
    _processedAlerts.add(alertKey);

    // Play auto-reject sound
    _audioService.playOrderAutoRejected();

    // Log timeout event
    _logTimeoutEvent(order, 'autoReject');

    // TODO: Trigger auto-rejection API call
    _autoRejectOrder(order);
  }

  /// Log timeout event to backend
  Future<void> _logTimeoutEvent(Order order, String timeoutType) async {
    try {
      // TODO: Implement API call when timeout logging endpoint is available
      developer.log(
          '📝 Would log timeout event: $timeoutType for order ${order.id}');
      developer.log(
          '✅ Timeout event logged locally: $timeoutType for order ${order.id}');
    } catch (e) {
      developer.log('❌ Failed to log timeout event: $e');
    }
  }

  /// Auto-reject order due to timeout
  Future<void> _autoRejectOrder(Order order) async {
    try {
      developer.log('🔄 Auto-rejecting order ${order.id} due to timeout');

      // Call the backend API to reject the order
      await _orderService.rejectMerchantOrder(
        order.id,
        reason: 'Order automatically rejected due to timeout (8 minutes)',
      );

      developer.log('✅ Order ${order.id} successfully auto-rejected via API');

      // Notify the UI to refresh orders
      onOrderAutoRejected?.call();
    } catch (e) {
      developer.log('❌ Failed to auto-reject order ${order.id}: $e');
      // Even if API call fails, we still mark it as processed to avoid spam
    }
  }

  /// Clear timeout alerts for a specific order (when manually handled)
  void clearOrderTimeouts(String orderId) {
    _processedAlerts.removeWhere((alert) => alert.startsWith(orderId));
    _lastTimeoutStatus.remove(orderId);
    developer.log('🧹 Cleared timeout alerts for order $orderId');
  }

  /// Get timeout statistics for analytics
  Map<String, int> getTimeoutStats() {
    final stats = <String, int>{};

    for (final alert in _processedAlerts) {
      if (alert.contains('_first')) {
        stats['firstAlerts'] = (stats['firstAlerts'] ?? 0) + 1;
      } else if (alert.contains('_urgent')) {
        stats['urgentAlerts'] = (stats['urgentAlerts'] ?? 0) + 1;
      } else if (alert.contains('_reject')) {
        stats['autoRejects'] = (stats['autoRejects'] ?? 0) + 1;
      }
    }

    return stats;
  }

  /// Update monitoring with new order list
  void updateOrders(List<Order> orders) {
    if (_monitoringTimer?.isActive ?? false) {
      _checkTimeouts(orders);
    }
  }

  /// Check if service is currently monitoring
  bool get isMonitoring => _monitoringTimer?.isActive ?? false;
}
