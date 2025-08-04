import 'package:amplify_flutter/amplify_flutter.dart';
import 'notification_helper.dart';
import 'audio_notification_service.dart';
import 'api_service.dart';

class PinpointService {
  static final PinpointService _instance = PinpointService._internal();
  factory PinpointService() => _instance;
  PinpointService._internal();

  bool _isInitialized = false;
  final AudioNotificationService _audioService = AudioNotificationService();

  /// Initialize Amazon Pinpoint push notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permissions
      final permissionResult =
          await Amplify.Notifications.Push.requestPermissions();
      print('🔔 Push notification permission granted: $permissionResult');

      if (!permissionResult) {
        print('❌ Push notifications not allowed');
        return;
      }

      // Listen for device token
      Amplify.Notifications.Push.onTokenReceived.listen((token) async {
        print('🔑 Pinpoint Device Token: $token');

        // Register token with backend
        if (token.isNotEmpty) {
          await ApiService().registerDeviceToken(token);
          print('✅ Device token registered with backend');
        }
      });

      // Set up notification handlers
      _setupNotificationHandlers();

      _isInitialized = true;
      print('✅ Pinpoint service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Pinpoint service: $e');
    }
  }

  /// Set up notification event handlers
  void _setupNotificationHandlers() {
    // Handle notification opened (when user taps notification)
    Amplify.Notifications.Push.onNotificationOpened.listen((notification) {
      print('📩 Notification opened: ${notification.title}');
      _handleNotificationTap(notification);
    });

    // Handle notification received in foreground
    Amplify.Notifications.Push.onNotificationReceivedInForeground
        .listen((notification) {
      print('📩 Foreground notification: ${notification.title}');
      _handleForegroundNotification(notification);
    });
  }

  /// Handle notification tap (when user opens the notification)
  void _handleNotificationTap(PushNotificationMessage notification) {
    final orderId = notification.data['orderId'];
    if (orderId != null) {
      // TODO: Navigate to order details page
      print('🔄 Navigate to order: $orderId');
    }
  }

  /// Handle foreground notification (when app is open)
  void _handleForegroundNotification(PushNotificationMessage notification) {
    // Show local notification
    NotificationHelper.showNotification(
      title: notification.title ?? 'New Order',
      body: notification.body ?? 'You have a new order!',
    );

    // Play notification sound
    _audioService.playNewOrderSound();

    // Track analytics event
    _trackNotificationEvent('received_foreground', notification);
  }

  /// Track notification analytics event
  void _trackNotificationEvent(
      String eventType, PushNotificationMessage notification) {
    try {
      // Analytics tracking can be implemented later
      print('📊 Analytics: $eventType - ${notification.title}');
    } catch (e) {
      print('Error tracking notification event: $e');
    }
  }

  /// Send a test notification (for debugging)
  Future<void> sendTestNotification() async {
    try {
      // This would typically be done from your backend
      print('📧 Test notification would be sent from backend');
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final status = await Amplify.Notifications.Push.getPermissionStatus();
      return status == PushNotificationPermissionStatus.granted;
    } catch (e) {
      print('Error checking notification permissions: $e');
      return false;
    }
  }

  /// Get current device token
  Future<String> getDeviceToken() async {
    try {
      // Token is received via onTokenReceived listener
      // We'll return empty string and rely on the listener
      return '';
    } catch (e) {
      print('Error getting device token: $e');
      return '';
    }
  }

  void dispose() {
    _audioService.dispose();
  }
}
