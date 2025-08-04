import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';
import 'notification_helper.dart';
import 'audio_notification_service.dart';
import 'api_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  final AudioNotificationService _audioService = AudioNotificationService();

  /// Initialize Firebase push notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if Firebase is properly configured
      // If project ID is still placeholder, skip Firebase initialization
      if (DefaultFirebaseOptions.currentPlatform.projectId ==
          'your-project-id') {
        print(
            '⚠️ Firebase not configured - using placeholder values. Push notifications disabled.');
        _isInitialized = true;
        return;
      }

      // Firebase is already initialized in main.dart

      // Request notification permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('🔔 Push notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('❌ Push notifications not allowed');
        return;
      }

      // Get device token
      final token = await messaging.getToken();
      print('🔑 Firebase Device Token: $token');

      // Register token with backend
      if (token != null && token.isNotEmpty) {
        await ApiService().registerDeviceToken(token);
        print('✅ Device token registered with backend');
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) async {
        print('🔄 Token refreshed: $newToken');
        await ApiService().registerDeviceToken(newToken);
      });

      // Set up notification handlers
      _setupNotificationHandlers();

      _isInitialized = true;
      print('✅ Firebase service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Firebase service: $e');
    }
  }

  /// Set up notification event handlers
  void _setupNotificationHandlers() {
    final messaging = FirebaseMessaging.instance;

    // Handle notification when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground notification: ${message.notification?.title}');
      _handleForegroundNotification(message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📩 Notification opened: ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    // Handle notification tap when app was terminated
    messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print(
            '📩 App launched from notification: ${message.notification?.title}');
        _handleNotificationTap(message);
      }
    });
  }

  /// Handle notification tap (when user opens the notification)
  void _handleNotificationTap(RemoteMessage message) {
    final orderId = message.data['orderId'];
    if (orderId != null) {
      // TODO: Navigate to order details page
      print('🔄 Navigate to order: $orderId');
    }
  }

  /// Handle foreground notification (when app is open)
  void _handleForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      // Show local notification
      NotificationHelper.showNotification(
        title: notification.title ?? 'New Order',
        body: notification.body ?? 'You have a new order!',
      );

      // Play notification sound
      _audioService.playNewOrderSound();
    }
  }

  /// Send a test notification (for debugging)
  Future<void> sendTestNotification() async {
    try {
      // This would typically be done from your backend via SNS
      print('📧 Test notification would be sent from backend via SNS');
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Error checking notification permissions: $e');
      return false;
    }
  }

  /// Get current device token
  Future<String> getDeviceToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      return token ?? '';
    } catch (e) {
      print('Error getting device token: $e');
      return '';
    }
  }

  void dispose() {
    _audioService.dispose();
  }
}
