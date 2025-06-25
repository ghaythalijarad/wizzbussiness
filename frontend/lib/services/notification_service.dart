import 'dart:convert';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../models/notification.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // WebSocket connection
  WebSocketChannel? _channel;
  StreamController<NotificationModel>? _notificationController;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  String? _currentBusinessId;
  String? _authToken;

  // Audio player for notification sounds
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Notification history
  final List<NotificationModel> _notifications = [];

  // Getters
  bool get isConnected => _isConnected;
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  Stream<NotificationModel>? get notificationStream =>
      _notificationController?.stream;

  static Future<void> init() async {
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
        // Handle notification tap
        if (response.payload != null) {
          _notificationService._handleNotificationTap(response.payload!);
        }
      },
    );

    // Initialize notification channels
    await _createNotificationChannels();
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
        'payments_channel',
        'Payment Notifications',
        description: 'Notifications for payment confirmations',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('payment_sound'),
      ),
      AndroidNotificationChannel(
        'urgent_channel',
        'Urgent Notifications',
        description: 'Urgent notifications requiring immediate attention',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('urgent_sound'),
      ),
      AndroidNotificationChannel(
        'general_channel',
        'General Notifications',
        description: 'General business notifications',
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

  // Connect to WebSocket
  Future<void> connectToNotifications(
      String businessId, String authToken) async {
    _currentBusinessId = businessId;
    _authToken = authToken;

    await _disconnectWebSocket();

    try {
      _notificationController = StreamController<NotificationModel>.broadcast();

      // Connect to WebSocket
      final wsUrl =
          'ws://localhost:8000/notifications/ws/notifications/$businessId';
      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: ['Bearer', authToken],
      );

      _isConnected = true;

      // Listen to incoming messages
      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketClose,
      );

      if (kDebugMode) {
        print('Connected to notification WebSocket for business: $businessId');
      }

      // Load notification history
      await _loadNotificationHistory();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to connect to WebSocket: $e');
      }
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  // Disconnect WebSocket
  Future<void> _disconnectWebSocket() async {
    _isConnected = false;
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _channel = null;
    await _notificationController?.close();
    _notificationController = null;
  }

  // Handle incoming WebSocket messages
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final notification = NotificationModel.fromJson(data);

      // Add to history
      _notifications.insert(0, notification);
      _saveNotificationHistory();

      // Show local notification
      _showLocalNotification(notification);

      // Play notification sound
      _playNotificationSound(notification);

      // Emit to stream
      _notificationController?.add(notification);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing notification message: $e');
      }
    }
  }

  // Handle WebSocket errors
  void _handleWebSocketError(error) {
    if (kDebugMode) {
      print('WebSocket error: $error');
    }
    _isConnected = false;
    _scheduleReconnect();
  }

  // Handle WebSocket close
  void _handleWebSocketClose() {
    if (kDebugMode) {
      print('WebSocket connection closed');
    }
    _isConnected = false;
    _scheduleReconnect();
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_currentBusinessId != null && _authToken != null) {
        connectToNotifications(_currentBusinessId!, _authToken!);
      }
    });
  }

  // Show local notification
  Future<void> _showLocalNotification(NotificationModel notification) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'orders_channel',
      'Order Notifications',
      channelDescription: 'Notifications for new orders and order updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      notification.id.hashCode,
      notification.title,
      notification.message,
      platformDetails,
      payload: jsonEncode(notification.toJson()),
    );
  }

  // Play notification sound
  Future<void> _playNotificationSound(NotificationModel notification) async {
    try {
      String soundFile = 'sounds/default_notification.mp3';

      switch (notification.type) {
        case 'new_order':
          soundFile = 'sounds/new_order.mp3';
          break;
        case 'payment_received':
          soundFile = 'sounds/payment_received.mp3';
          break;
        case 'urgent':
          soundFile = 'sounds/urgent_notification.mp3';
          break;
      }

      await _audioPlayer.play(AssetSource(soundFile));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing notification sound: $e');
      }
    }
  }

  // Handle notification tap
  void _handleNotificationTap(String payload) {
    try {
      final data = jsonDecode(payload);
      final notification = NotificationModel.fromJson(data);

      // Mark as read
      markAsRead(notification.id);

      // Handle navigation based on notification type
      _navigateToNotificationContent(notification);
    } catch (e) {
      if (kDebugMode) {
        print('Error handling notification tap: $e');
      }
    }
  }

  // Navigate to notification content
  void _navigateToNotificationContent(NotificationModel notification) {
    // This would typically use a navigation service or callback
    // For now, we'll just print the action
    if (kDebugMode) {
      print('Navigate to ${notification.type} with data: ${notification.data}');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    if (_currentBusinessId == null) return;

    try {
      // Update locally
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _saveNotificationHistory();
      }

      // Update on server
      final apiService = ApiService();
      await apiService.markNotificationAsRead(
          _currentBusinessId!, notificationId);
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  // Get notification history from server
  Future<void> _loadNotificationHistory() async {
    if (_currentBusinessId == null) return;

    try {
      final apiService = ApiService();
      final history =
          await apiService.getNotificationHistory(_currentBusinessId!);

      _notifications.clear();
      _notifications.addAll(history);
      _saveNotificationHistory();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notification history: $e');
      }
    }
  }

  // Save notification history locally
  Future<void> _saveNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString(
          'notification_history', jsonEncode(notificationsJson));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving notification history: $e');
      }
    }
  }

  // Load notification history locally
  Future<void> _loadLocalNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('notification_history');

      if (historyJson != null) {
        final List<dynamic> notificationsData = jsonDecode(historyJson);
        _notifications.clear();
        _notifications.addAll(
          notificationsData.map((data) => NotificationModel.fromJson(data)),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading local notification history: $e');
      }
    }
  }

  // Legacy method for backward compatibility
  static Future<void> showNotification(
      AppLocalizations loc, String title, String body) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      businessId: '',
      type: 'general',
      title: title,
      message: body,
      data: {},
      priority: 'normal',
      timestamp: DateTime.now(),
    );

    await _notificationService._showLocalNotification(notification);
  }

  static void showOrderNotification(AppLocalizations loc, Order order) {
    final formattedTitle = loc.newOrderReceived(order.customerName);
    final formattedMessage = loc.newOrderReceived(order.customerName);
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      businessId: '',
      type: 'new_order',
      title: formattedTitle,
      message: formattedMessage,
      data: {'order_id': order.id, 'customer_name': order.customerName},
      priority: 'high',
      timestamp: DateTime.now(),
    );

    _notificationService._showLocalNotification(notification);
    _notificationService._playNotificationSound(notification);
  }

  // Send test notification (for testing purposes)
  Future<void> sendTestNotification() async {
    if (_currentBusinessId == null) return;

    try {
      final apiService = ApiService();
      await apiService.sendTestNotification(_currentBusinessId!);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending test notification: $e');
      }
    }
  }

  // Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    _saveNotificationHistory();
  }

  // Dispose resources
  Future<void> dispose() async {
    await _disconnectWebSocket();
    _reconnectTimer?.cancel();
    await _audioPlayer.dispose();
  }
}
