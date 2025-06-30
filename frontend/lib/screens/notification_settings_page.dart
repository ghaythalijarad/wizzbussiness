import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';
import '../services/simple_notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _useSimpleNotifications = false;
  bool _isLoading = false;
  String? _currentBusinessId;
  String? _authToken;

  // Simple notification settings
  Duration _pollingInterval = const Duration(seconds: 30);
  bool _showLocalNotifications = true;
  bool _playNotificationSounds = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _useSimpleNotifications =
          prefs.getBool('use_simple_notifications') ?? false;
      _showLocalNotifications =
          prefs.getBool('show_local_notifications') ?? true;
      _playNotificationSounds =
          prefs.getBool('play_notification_sounds') ?? true;

      // Load polling interval (in seconds)
      final pollingSeconds = prefs.getInt('polling_interval_seconds') ?? 30;
      _pollingInterval = Duration(seconds: pollingSeconds);

      // Load current business context
      _currentBusinessId = prefs.getString('current_business_id');
      _authToken = prefs.getString('access_token');

      setState(() {});
    } catch (e) {
      _showError('Failed to load notification settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('use_simple_notifications', _useSimpleNotifications);
      await prefs.setBool('show_local_notifications', _showLocalNotifications);
      await prefs.setBool('play_notification_sounds', _playNotificationSounds);
      await prefs.setInt(
          'polling_interval_seconds', _pollingInterval.inSeconds);

      // Apply the notification system change
      await _applyNotificationSystemChange();

      _showSuccess('Notification settings saved successfully!');
    } catch (e) {
      _showError('Failed to save notification settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyNotificationSystemChange() async {
    if (_currentBusinessId == null || _authToken == null) return;

    if (_useSimpleNotifications) {
      // Switch to simple notifications
      await NotificationService().dispose();
      await SimpleNotificationService()
          .startPolling(_currentBusinessId!, _authToken!);
      SimpleNotificationService().setPollingInterval(_pollingInterval);
    } else {
      // Switch to complex notifications
      await SimpleNotificationService().stopPolling();
      await NotificationService()
          .connectToNotifications(_currentBusinessId!, _authToken!);
    }
  }

  Future<void> _testNotification() async {
    setState(() => _isLoading = true);

    try {
      if (_useSimpleNotifications) {
        await SimpleNotificationService().sendTestNotification();
      } else {
        await NotificationService().sendTestNotification();
      }

      _showSuccess('Test notification sent!');
    } catch (e) {
      _showError('Failed to send test notification: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.notifications),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification System Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notification System',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),

                          // Simple Notifications
                          RadioListTile<bool>(
                            title: const Text(
                                'Simple Notifications (Cloud-Friendly)'),
                            subtitle: const Text(
                              'HTTP polling-based notifications. More reliable on cloud platforms. '
                              'Uses less resources but may have slight delays.',
                            ),
                            value: true,
                            groupValue: _useSimpleNotifications,
                            onChanged: (value) {
                              setState(() => _useSimpleNotifications = value!);
                            },
                          ),

                          // Complex Notifications
                          RadioListTile<bool>(
                            title: const Text(
                                'Real-time Notifications (WebSocket)'),
                            subtitle: const Text(
                              'WebSocket-based real-time notifications. Instant delivery but may have '
                              'connection issues on some cloud platforms.',
                            ),
                            value: false,
                            groupValue: _useSimpleNotifications,
                            onChanged: (value) {
                              setState(() => _useSimpleNotifications = value!);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Simple Notification Settings
                  if (_useSimpleNotifications) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Simple Notification Settings',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),

                            // Polling Interval
                            Row(
                              children: [
                                const Icon(Icons.timer),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Polling Interval: ${_pollingInterval.inSeconds} seconds',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),

                            Slider(
                              value: _pollingInterval.inSeconds.toDouble(),
                              min: 10,
                              max: 300,
                              divisions: 29,
                              label: '${_pollingInterval.inSeconds}s',
                              onChanged: (value) {
                                setState(() {
                                  _pollingInterval =
                                      Duration(seconds: value.toInt());
                                });
                              },
                            ),

                            Text(
                              'Lower values provide faster updates but use more battery and data.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),

                            const SizedBox(height: 16),

                            // Local Notifications Toggle
                            SwitchListTile(
                              title: Text(loc.showLocalNotifications),
                              subtitle:
                                  Text(loc.showLocalNotificationsDescription),
                              value: _showLocalNotifications,
                              onChanged: (value) {
                                setState(() => _showLocalNotifications = value);
                              },
                            ),

                            // Notification Sounds Toggle
                            SwitchListTile(
                              title: Text(loc.playNotificationSounds),
                              subtitle:
                                  Text(loc.playNotificationSoundsDescription),
                              value: _playNotificationSounds,
                              onChanged: (value) {
                                setState(() => _playNotificationSounds = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Test Notification Button
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.testNotifications,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _testNotification,
                            icon: const Icon(Icons.notification_add),
                            label: Text(loc.sendTestNotification),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.testNotificationDescription,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Information Card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Deployment Information',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.blue.shade700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Simple Notifications are recommended for cloud deployment\n'
                            '• WebSocket notifications work better on dedicated servers\n'
                            '• You can switch between systems anytime\n'
                            '• Changes take effect immediately after saving',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
