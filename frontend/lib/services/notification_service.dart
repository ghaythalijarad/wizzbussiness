import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../providers/order_providers.dart'; // To invalidate order lists
import 'order_service.dart';

// Provider for the NotificationService
final notificationServiceProvider =
    ChangeNotifierProvider<NotificationService>((ref) {
  return NotificationService(ref);
});

/// Service for managing application notifications
class NotificationService extends ChangeNotifier {
  final Ref _ref;
  NotificationService(this._ref);

  final List<NotificationModel> _notifications = [];
  bool _enabled = true;
  bool _soundEnabled = true;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get enabled => _enabled;
  bool get soundEnabled => _soundEnabled;

  /// Add a new notification
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification); // Add at beginning for newest first
    notifyListeners();
    debugPrint('📧 Notification added: ${notification.title}');
  }

  /// Handles an action from a notification, like 'Accept' or 'Reject'
  Future<void> handleOrderAction(String orderId, String action) async {
    debugPrint('Handling action "$action" for order "$orderId"');
    try {
      final orderService = OrderService();
      bool success = false;
      if (action == 'ACCEPT_ORDER') {
        await orderService.acceptMerchantOrder(orderId);
        success = true;
      } else if (action == 'REJECT_ORDER') {
        await orderService.rejectMerchantOrder(orderId);
        success = true;
      }

      if (success) {
        debugPrint(
            'Action "$action" for order "$orderId" was successful. Invalidating order providers.');
        // Invalidate providers to force a refresh of the order lists in the UI
        _ref.invalidate(pendingOrdersProvider);
        _ref.invalidate(confirmedOrdersProvider);
        _ref.invalidate(allOrdersProvider);

        // Optionally, remove the notification from the list now that it's handled
        _notifications.removeWhere((n) => n.data['orderId'] == orderId);
        notifyListeners();
      } else {
        debugPrint('Failed to handle action "$action" for order "$orderId"');
        // Optionally, show an error to the user
      }
    } catch (e) {
      debugPrint('Error handling order action: $e');
      // Optionally, show an error to the user
    }
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  /// Remove a notification
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  /// Clear all notifications (alias method)
  void clearAllNotifications() {
    clearAll();
  }

  /// Get unread count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Enable/disable notifications
  void setEnabled(bool enabled) {
    _enabled = enabled;
    notifyListeners();
  }

  /// Enable/disable notification sounds
  void setSoundEnabled(bool soundEnabled) {
    _soundEnabled = soundEnabled;
    notifyListeners();
  }

  /// Add an order notification
  void addOrderNotification({
    required String title,
    required String message,
    String? orderId,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      businessId: 'default', // You might want to pass this as parameter
      type: 'order',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      data: orderId != null ? {'orderId': orderId} : {},
      priority: 'normal',
    );
    addNotification(notification);
  }

  /// Add a system notification
  void addSystemNotification({
    required String title,
    required String message,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      businessId: 'default', // You might want to pass this as parameter
      type: 'system',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      data: {},
      priority: 'normal',
    );
    addNotification(notification);
  }

  /// Connect to notifications (placeholder method)
  Future<void> connectToNotifications() async {
    debugPrint('📡 Connecting to notifications...');
    // Placeholder implementation
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    addSystemNotification(
      title: 'Test Notification',
      message: 'This is a test notification to verify the system is working.',
    );
  }

  /// Check if connected (placeholder)
  bool get isConnected => true;

  /// Notification stream (placeholder)
  Stream<NotificationModel> get notificationStream async* {
    // Placeholder stream implementation
  }
}
