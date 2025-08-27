import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _newOrderNotifications = true;
  bool _orderStatusNotifications = true;
  bool _paymentNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _pushNotifications = prefs.getBool('notif_push') ?? true;
        _emailNotifications = prefs.getBool('notif_email') ?? true;
        _smsNotifications = prefs.getBool('notif_sms') ?? false;
        _newOrderNotifications = prefs.getBool('notif_new_order') ?? true;
        _orderStatusNotifications = prefs.getBool('notif_order_status') ?? true;
        _paymentNotifications = prefs.getBool('notif_payment') ?? true;
      });
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF32CD32).withOpacity(0.05), // Lime Green
              const Color(0xFFFFD300).withOpacity(0.03), // Gold
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery Methods Section
                _buildNotificationSection(
                        'Delivery Methods',
                  Icons.send,
                  const Color(0xFF32CD32),
                  [
                    _buildModernSwitchTile(
                      'Push Notifications',
                      'Receive notifications on your device',
                      _pushNotifications,
                      (value) => setState(() => _pushNotifications = value),
                      Icons.notifications,
                      const Color(0xFF32CD32),
                    ),
                    _buildModernSwitchTile(
                      'Email Notifications',
                      'Receive notifications via email',
                      _emailNotifications,
                      (value) => setState(() => _emailNotifications = value),
                      Icons.email,
                      const Color(0xFFFFD300),
                    ),
                    _buildModernSwitchTile(
                      'SMS Notifications',
                      'Receive notifications via SMS (charges may apply)',
                      _smsNotifications,
                      (value) => setState(() => _smsNotifications = value),
                      Icons.sms,
                      const Color(0xFF32CD32),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Order Notifications Section
                _buildNotificationSection(
                  'Order Notifications',
                  Icons.shopping_cart,
                  const Color(0xFFFFD300),
                  [
                    _buildModernSwitchTile(
                      'New Orders',
                      'Get notified when new orders arrive',
                      _newOrderNotifications,
                      (value) => setState(() => _newOrderNotifications = value),
                      Icons.add_shopping_cart,
                      const Color(0xFF32CD32),
                    ),
                    _buildModernSwitchTile(
                      'Order Status Updates',
                      'Get notified when order status changes',
                      _orderStatusNotifications,
                      (value) =>
                          setState(() => _orderStatusNotifications = value),
                      Icons.update,
                      const Color(0xFFFFD300),
                    ),
                    _buildModernSwitchTile(
                      'Payment Notifications',
                      'Get notified about payment updates',
                      _paymentNotifications,
                      (value) => setState(() => _paymentNotifications = value),
                      Icons.payment,
                      const Color(0xFF32CD32),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSection(
      String title, IconData icon, Color iconColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withOpacity(0.1),
                  iconColor.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSwitchTile(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: iconColor,
            activeTrackColor: iconColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
