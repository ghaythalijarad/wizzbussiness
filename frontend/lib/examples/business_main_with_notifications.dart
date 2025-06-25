import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';
import '../widgets/notification_panel.dart';

// Example: How to integrate the notification system into your main business app

class BusinessMainScreen extends StatefulWidget {
  final String businessId;
  final String authToken;

  const BusinessMainScreen({
    Key? key,
    required this.businessId,
    required this.authToken,
  }) : super(key: key);

  @override
  State<BusinessMainScreen> createState() => _BusinessMainScreenState();
}

class _BusinessMainScreenState extends State<BusinessMainScreen> {
  final NotificationService _notificationService = NotificationService();
  int _unreadNotifications = 0;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      // Initialize the notification system
      await NotificationService.init();

      // Connect to business-specific notifications
      await _notificationService.connectToNotifications(
        widget.businessId,
        widget.authToken,
      );

      // Listen to real-time notifications
      _notificationService.notificationStream?.listen((notification) {
        setState(() {
          _unreadNotifications =
              _notificationService.notifications.where((n) => !n.isRead).length;
          _isConnected = _notificationService.isConnected;
        });

        // Handle different notification types
        _handleNewNotification(notification);
      });

      setState(() {
        _isConnected = _notificationService.isConnected;
        _unreadNotifications =
            _notificationService.notifications.where((n) => !n.isRead).length;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleNewNotification(NotificationModel notification) {
    // Show different responses based on notification type
    if (notification.isNewOrder) {
      _showNewOrderDialog(notification);
    } else if (notification.type == 'payment_received') {
      _showPaymentConfirmation(notification);
    } else if (notification.isHighPriority) {
      _showUrgentAlert(notification);
    }
  }

  void _showNewOrderDialog(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.green),
              SizedBox(width: 8),
              Text('New Order!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              const SizedBox(height: 16),
              Text(
                'Customer: ${notification.data['customer_name'] ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (notification.data['order_total'] != null)
                Text(
                  'Total: \$${notification.data['order_total']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _viewOrderDetails(notification.data['order_id']);
              },
              child: const Text('View Order'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentConfirmation(NotificationModel notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.payment, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(notification.message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showUrgentAlert(NotificationModel notification) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red[50],
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Urgent Alert', style: TextStyle(color: Colors.red)),
            ],
          ),
          content: Text(notification.message),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Understood'),
            ),
          ],
        );
      },
    );
  }

  void _viewOrderDetails(String? orderId) {
    if (orderId != null) {
      // Navigate to order details screen
      Navigator.pushNamed(context, '/order-details', arguments: orderId);
    }
  }

  void _openNotificationPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationPanel(
          businessId: widget.businessId,
          authToken: widget.authToken,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mario\'s Pizza Palace'),
        backgroundColor: const Color(0xFF007fff),
        foregroundColor: Colors.white,
        actions: [
          // Connection status indicator
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Icon(
                _isConnected ? Icons.wifi : Icons.wifi_off,
                color: _isConnected ? Colors.white : Colors.red[200],
                size: 20,
              ),
            ),
          ),

          // Notification button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _openNotificationPanel,
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status banner
          if (!_isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange,
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Not connected to real-time notifications',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // Your existing business app content goes here
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store, size: 64, color: Color(0xFF007fff)),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to Your Business Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll receive instant notifications when customers place orders',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Quick stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('Connected', _isConnected ? 'Yes' : 'No',
                          _isConnected ? Colors.green : Colors.red),
                      _buildStatCard('Unread', '$_unreadNotifications',
                          const Color(0xFF007fff)),
                      _buildStatCard('Status', 'Active', Colors.green),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Test notification button
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _notificationService.sendTestNotification();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test notification sent!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to send test notification'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Send Test Notification'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNotificationPanel,
        tooltip: 'Open Notifications',
        child: Stack(
          children: [
            const Icon(Icons.notifications),
            if (_unreadNotifications > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    '$_unreadNotifications',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Example usage in your main.dart:
/*
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Business App',
      theme: ThemeData(
        primarySwatch: MaterialColor(
          0xFF007fff,
          const <int, Color>{
            50: Color(0xFFE0F2FF),
            100: Color(0xFFB3DEFF),
            200: Color(0xFF80C9FF),
            300: Color(0xFF4DB3FF),
            400: Color(0xFF26A3FF),
            500: Color(0xFF007fff),
            600: Color(0xFF0077FF),
            700: Color(0xFF006CFF),
            800: Color(0xFF0062FF),
            900: Color(0xFF004FFF),
          },
        ),
        primaryColor: const Color(0xFF007fff),
      ),
      home: BusinessMainScreen(
        businessId: "YOUR_BUSINESS_ID_HERE",
        authToken: "YOUR_AUTH_TOKEN_HERE",
      ),
    );
  }
}
*/
