import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';
import '../l10n/app_localizations.dart';

class NotificationPanel extends StatefulWidget {
  final String businessId;
  final String authToken;

  const NotificationPanel({
    Key? key,
    required this.businessId,
    required this.authToken,
  }) : super(key: key);

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  final NotificationService _notificationService = NotificationService();
  bool _isConnected = false;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      // Connect to real-time notifications
      await _notificationService.connectToNotifications(
        widget.businessId,
        widget.authToken,
      );

      // Listen to notification stream
      _notificationService.notificationStream?.listen((notification) {
        setState(() {
          _notifications = _notificationService.notifications;
        });

        // Show a snackbar for new high-priority notifications
        if (notification.isHighPriority) {
          _showNotificationSnackBar(notification);
        }
      });

      setState(() {
        _isConnected = _notificationService.isConnected;
        _notifications = _notificationService.notifications;
      });
    } catch (e) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.failedToConnectToNotifications
              .replaceAll('{error}', e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNotificationSnackBar(NotificationModel notification) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(notification.message),
          ],
        ),
        backgroundColor:
            notification.isHighPriority ? Colors.red : const Color(0xFF007fff),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.view,
          textColor: Colors.white,
          onPressed: () => _viewNotification(notification),
        ),
      ),
    );
  }

  void _viewNotification(NotificationModel notification) {
    // Mark as read
    _notificationService.markAsRead(notification.id);

    // Navigate to relevant screen based on notification type
    if (notification.isNewOrder) {
      _navigateToOrderDetails(notification.data['order_id']);
    }
  }

  void _navigateToOrderDetails(String? orderId) {
    if (orderId != null) {
      // Navigate to order details screen
      Navigator.pushNamed(context, '/order-details', arguments: orderId);
    }
  }

  Future<void> _sendTestNotification() async {
    final loc = AppLocalizations.of(context)!;
    try {
      await _notificationService.sendTestNotification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.testNotificationSentSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.failedToSendTestNotification
              .replaceAll('{error}', e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.notificationsTitle),
        backgroundColor: const Color(0xFF007fff),
        foregroundColor: Colors.white,
        actions: [
          // Connection status indicator
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _isConnected ? loc.live : loc.offline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Test notification button
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendTestNotification,
            tooltip: loc.sendTestNotification,
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
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    loc.notConnectedToNotifications,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // Notification statistics
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    loc.total,
                    _notifications.length.toString(),
                    Icons.notifications,
                    const Color(0xFF007fff),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    loc.unread,
                    _notifications.where((n) => !n.isRead).length.toString(),
                    Icons.mark_email_unread,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    loc.highPriority,
                    _notifications
                        .where((n) => n.isHighPriority)
                        .length
                        .toString(),
                    Icons.priority_high,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Notifications list
          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          loc.noNotificationsYet,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          loc.newOrderNotificationsAppearHere,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _notificationService.clearAllNotifications();
          setState(() {
            _notifications = [];
          });
        },
        tooltip: AppLocalizations.of(context)!.clearAllNotifications,
        child: const Icon(Icons.clear_all),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: notification.isRead ? 1 : 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification),
          child: Icon(
            _getNotificationIcon(notification),
            color: Colors.white,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatTime(notification.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(notification.priority),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notification.priority.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () => _viewNotification(notification),
      ),
    );
  }

  Color _getNotificationColor(NotificationModel notification) {
    switch (notification.type) {
      case 'new_order':
        return Colors.green;
      case 'payment_received':
        return const Color(0xFF007fff);
      case 'order_update':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(NotificationModel notification) {
    switch (notification.type) {
      case 'new_order':
        return Icons.shopping_cart;
      case 'payment_received':
        return Icons.payment;
      case 'order_update':
        return Icons.update;
      case 'urgent':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'normal':
        return const Color(0xFF007fff);
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final loc = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return loc.justNow;
    } else if (difference.inMinutes < 60) {
      return loc.minutesAgo
          .replaceAll('{minutes}', difference.inMinutes.toString());
    } else if (difference.inHours < 24) {
      return loc.hoursAgo.replaceAll('{hours}', difference.inHours.toString());
    } else {
      return loc.daysAgo.replaceAll('{days}', difference.inDays.toString());
    }
  }
}
