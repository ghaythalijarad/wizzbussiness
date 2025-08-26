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
  bool _systemNotifications = true;
  bool _marketingNotifications = false;
  bool _weeklyReports = true;
  bool _monthlyReports = true;
  
  // Quiet Hours Settings
  bool _enableQuietHours = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 8, minute: 0);

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
        _systemNotifications = prefs.getBool('notif_system') ?? true;
        _marketingNotifications = prefs.getBool('notif_marketing') ?? false;
        _weeklyReports = prefs.getBool('notif_weekly_reports') ?? true;
        _monthlyReports = prefs.getBool('notif_monthly_reports') ?? true;
        _enableQuietHours = prefs.getBool('notif_quiet_hours') ?? false;
      });
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notif_push', _pushNotifications);
      await prefs.setBool('notif_email', _emailNotifications);
      await prefs.setBool('notif_sms', _smsNotifications);
      await prefs.setBool('notif_new_order', _newOrderNotifications);
      await prefs.setBool('notif_order_status', _orderStatusNotifications);
      await prefs.setBool('notif_payment', _paymentNotifications);
      await prefs.setBool('notif_system', _systemNotifications);
      await prefs.setBool('notif_marketing', _marketingNotifications);
      await prefs.setBool('notif_weekly_reports', _weeklyReports);
      await prefs.setBool('notif_monthly_reports', _monthlyReports);
      await prefs.setBool('notif_quiet_hours', _enableQuietHours);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _quietHoursStart : _quietHoursEnd,
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _quietHoursStart = picked;
        } else {
          _quietHoursEnd = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Delivery Methods
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.send, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Text(
                        'Delivery Methods',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle:
                        const Text('Receive notifications on your device'),
                    value: _pushNotifications,
                    onChanged: (value) {
                      setState(() {
                        _pushNotifications = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Email Notifications'),
                    subtitle: const Text('Receive notifications via email'),
                    value: _emailNotifications,
                    onChanged: (value) {
                      setState(() {
                        _emailNotifications = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('SMS Notifications'),
                    subtitle: const Text(
                        'Receive notifications via SMS (charges may apply)'),
                    value: _smsNotifications,
                    onChanged: (value) {
                      setState(() {
                        _smsNotifications = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Order Notifications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_cart,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Text(
                        'Order Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('New Orders'),
                    subtitle: const Text('Get notified when new orders arrive'),
                    value: _newOrderNotifications,
                    onChanged: (value) {
                      setState(() {
                        _newOrderNotifications = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Order Status Updates'),
                    subtitle:
                        const Text('Get notified when order status changes'),
                    value: _orderStatusNotifications,
                    onChanged: (value) {
                      setState(() {
                        _orderStatusNotifications = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Payment Notifications'),
                    subtitle: const Text('Get notified about payment updates'),
                    value: _paymentNotifications,
                    onChanged: (value) {
                      setState(() {
                        _paymentNotifications = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // System & Marketing
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Text(
                        'System & Marketing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('System Notifications'),
                    subtitle: const Text('Important system updates and alerts'),
                    value: _systemNotifications,
                    onChanged: (value) {
                      setState(() {
                        _systemNotifications = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Marketing Notifications'),
                    subtitle: const Text('Promotions and marketing updates'),
                    value: _marketingNotifications,
                    onChanged: (value) {
                      setState(() {
                        _marketingNotifications = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Reports
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assessment,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Text(
                        'Reports',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Weekly Reports'),
                    subtitle: const Text(
                        'Receive weekly business performance reports'),
                    value: _weeklyReports,
                    onChanged: (value) {
                      setState(() {
                        _weeklyReports = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Monthly Reports'),
                    subtitle: const Text('Receive monthly business analytics'),
                    value: _monthlyReports,
                    onChanged: (value) {
                      setState(() {
                        _monthlyReports = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quiet Hours
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bedtime,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Text(
                        'Quiet Hours',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Quiet Hours'),
                    subtitle:
                        const Text('Reduce notifications during quiet hours'),
                    value: _enableQuietHours,
                    onChanged: (value) {
                      setState(() {
                        _enableQuietHours = value;
                      });
                    },
                  ),
                  if (_enableQuietHours) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Start Time'),
                            subtitle: Text(_formatTime(_quietHoursStart)),
                            trailing: const Icon(Icons.access_time),
                            onTap: () => _selectTime(true),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('End Time'),
                            subtitle: Text(_formatTime(_quietHoursEnd)),
                            trailing: const Icon(Icons.access_time),
                            onTap: () => _selectTime(false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
