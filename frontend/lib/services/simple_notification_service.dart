import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../models/notification.dart';
import 'api_service.dart';

/// Simplified notification service for Heroku deployment
///
/// This service uses HTTP polling instead of WebSockets to be more compatible
/// with Heroku's ephemeral environment and avoid connection management complexity.
class SimpleNotificationService {
  static final SimpleNotificationService _instance =
      SimpleNotificationService._internal();

  factory SimpleNotificationService() {
    return _instance;
  }

  SimpleNotificationService._internal();

  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // HTTP polling configuration
  Timer? _pollingTimer;
  String? _currentBusinessId;
  String? _authToken;

  // Audio player for notification sounds
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Notification history
  List<NotificationModel> _notifications = [];
  int _lastUnreadCount = 0;

  // Stream controller for notification updates
  StreamController<NotificationModel>? _notificationController;
  StreamController<int>? _unreadCountController;

  // Polling interval (adjustable based on needs)
  Duration _pollingInterval = const Duration(seconds: 30);

  // Getters
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  Stream<NotificationModel>? get notificationStream =>
      _notificationController?.stream;
  Stream<int>? get unreadCountStream => _unreadCountController?.stream;
  bool get isPolling => _pollingTimer != null && _pollingTimer!.isActive;

  /// Initialize the notification service
  static Future<void> init() async {
    await _createNotificationChannels();

    // Initialize local notification plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print('Notification tapped: ${response.payload}');
        }
      },
    );

    if (kDebugMode) {
      print('Simple notification service initialized');
    }
  }

  static Future<void> _createNotificationChannels() async {
    // Create channels for different types of notifications
    const List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        'orders_channel',
        'Order Notifications',
        description: 'Notifications for new orders and order updates',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('order_sound'),
      ),
      AndroidNotificationChannel(
        'system_channel',
        'System Notifications',
        description: 'System messages and updates',
        importance: Importance.defaultImportance,
      ),
    ];

    final plugin = FlutterLocalNotificationsPlugin();
    for (final channel in channels) {
      await plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Start polling for notifications
  Future<void> startPolling(String businessId, String authToken) async {
    _currentBusinessId = businessId;
    _authToken = authToken;

    // Initialize stream controllers
    _notificationController ??= StreamController<NotificationModel>.broadcast();
    _unreadCountController ??= StreamController<int>.broadcast();

    // Load stored notifications
    await _loadNotificationHistory();

    // Start polling
    _startPollingTimer();

    if (kDebugMode) {
      print('Started polling notifications for business: $businessId');
    }
  }

  /// Stop polling for notifications
  Future<void> stopPolling() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;

    await _notificationController?.close();
    await _unreadCountController?.close();
    _notificationController = null;
    _unreadCountController = null;

    _currentBusinessId = null;
    _authToken = null;

    if (kDebugMode) {
      print('Stopped polling notifications');
    }
  }

  /// Manually refresh notifications (pull-to-refresh)
  Future<void> refresh() async {
    if (_currentBusinessId != null && _authToken != null) {
      await _pollForNotifications();
    }
  }

  /// Set polling interval
  void setPollingInterval(Duration interval) {
    _pollingInterval = interval;
    if (isPolling) {
      // Restart polling with new interval
      _pollingTimer?.cancel();
      _startPollingTimer();
    }
  }

  void _startPollingTimer() {
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
      _pollForNotifications();
    });

    // Initial poll
    _pollForNotifications();
  }

  Future<void> _pollForNotifications() async {
    if (_currentBusinessId == null || _authToken == null) return;

    try {
      final apiService = ApiService();

      // Get latest notifications
      final response = await http.get(
        Uri.parse(
            'http://localhost:8001/api/simple/notifications/$_currentBusinessId?limit=50'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> notificationsJson = data['notifications'] ?? [];
        final int unreadCount = data['unread_count'] ?? 0;

        // Convert to notification models
        final List<NotificationModel> newNotifications = notificationsJson
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        // Check for new notifications
        final Set<String> existingIds = _notifications.map((n) => n.id).toSet();
        final List<NotificationModel> trulyNewNotifications =
            newNotifications.where((n) => !existingIds.contains(n.id)).toList();

        // Update notifications list
        _notifications = newNotifications;
        await _saveNotificationHistory();

        // Show local notifications for new ones
        for (final notification in trulyNewNotifications) {
          await _showLocalNotification(notification);
          await _playNotificationSound(notification);
          _notificationController?.add(notification);
        }

        // Update unread count if changed
        if (unreadCount != _lastUnreadCount) {
          _lastUnreadCount = unreadCount;
          _unreadCountController?.add(unreadCount);
        }

        if (kDebugMode && trulyNewNotifications.isNotEmpty) {
          print('Received ${trulyNewNotifications.length} new notifications');
        }
      } else {
        if (kDebugMode) {
          print('Failed to poll notifications: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error polling notifications: $e');
      }
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    if (_currentBusinessId == null || _authToken == null) return;

    try {
      final response = await http.post(
        Uri.parse(
            'http://localhost:8001/api/simple/notifications/$_currentBusinessId/$notificationId/mark-read'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update local notification
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          await _saveNotificationHistory();
        }

        // Refresh to get updated unread count
        await _pollForNotifications();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_currentBusinessId == null || _authToken == null) return;

    try {
      final response = await http.post(
        Uri.parse(
            'http://localhost:8001/api/simple/notifications/$_currentBusinessId/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update local notifications
        _notifications =
            _notifications.map((n) => n.copyWith(isRead: true)).toList();
        await _saveNotificationHistory();

        // Update unread count
        _lastUnreadCount = 0;
        _unreadCountController?.add(0);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    if (_currentBusinessId == null || _authToken == null) return;

    try {
      final response = await http.post(
        Uri.parse(
            'http://localhost:8001/api/simple/notifications/$_currentBusinessId/test'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Refresh to get the test notification
        await Future.delayed(const Duration(seconds: 1));
        await _pollForNotifications();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending test notification: $e');
      }
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    if (_currentBusinessId == null || _authToken == null) return 0;

    try {
      final response = await http.get(
        Uri.parse(
            'http://localhost:8001/api/simple/notifications/$_currentBusinessId/unread-count'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'] ?? 0;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unread count: $e');
      }
    }

    return 0;
  }

  Future<void> _showLocalNotification(NotificationModel notification) async {
    String channelId = 'system_channel';
    if (notification.type == 'new_order' ||
        notification.type == 'order_update') {
      channelId = 'orders_channel';
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelId == 'orders_channel'
          ? 'Order Notifications'
          : 'System Notifications',
      channelDescription: channelId == 'orders_channel'
          ? 'Notifications for new orders and order updates'
          : 'System messages and updates',
      importance: notification.priority == 'high'
          ? Importance.max
          : Importance.defaultImportance,
      priority: notification.priority == 'high'
          ? Priority.high
          : Priority.defaultPriority,
      showWhen: true,
      styleInformation: BigTextStyleInformation(
        notification.message,
        contentTitle: notification.title,
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.message,
      notificationDetails,
      payload: jsonEncode(notification.toJson()),
    );
  }

  Future<void> _playNotificationSound(NotificationModel notification) async {
    try {
      String soundFile = 'sounds/default_notification.mp3';

      if (notification.type == 'new_order') {
        soundFile = 'sounds/new_order.mp3';
      } else if (notification.priority == 'high') {
        soundFile = 'sounds/urgent_notification.mp3';
      }

      await _audioPlayer.play(AssetSource(soundFile), volume: 0.8);
    } catch (e) {
      if (kDebugMode) {
        print('Error playing notification sound: $e');
      }
    }
  }

  Future<void> _loadNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson =
          prefs.getString('simple_notification_history_$_currentBusinessId');

      if (historyJson != null) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        _notifications = historyList
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notification history: $e');
      }
    }
  }

  Future<void> _saveNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson =
          jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(
          'simple_notification_history_$_currentBusinessId', historyJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving notification history: $e');
      }
    }
  }

  // Static helper methods for showing notifications without service instance
  static void showOrderNotification(AppLocalizations loc, Order order) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      businessId: '',
      type: 'new_order',
      title: loc.newOrderReceived(order.customerName),
      message: 'Order #${order.orderNumber} - \$${order.totalAmount}',
      data: {'order_id': order.id, 'customer_name': order.customerName},
      priority: 'high',
      timestamp: DateTime.now(),
    );

    _instance._showLocalNotification(notification);
    _instance._playNotificationSound(notification);
  }

  static void showGeneralNotification(String title, String body) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      businessId: '',
      type: 'system_message',
      title: title,
      message: body,
      data: {},
      priority: 'normal',
      timestamp: DateTime.now(),
    );

    _instance._showLocalNotification(notification);
  }

  /// Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    _saveNotificationHistory();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopPolling();
    await _audioPlayer.dispose();
  }
}
