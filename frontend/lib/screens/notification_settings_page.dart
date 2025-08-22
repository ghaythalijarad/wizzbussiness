import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/simple_notification_service.dart';
import '../theme/cravevolt_theme.dart';

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
      // Note: NotificationService disposal should be handled by the provider
      SimpleNotificationService().startPolling();
      SimpleNotificationService().setPollingInterval(_pollingInterval);
    } else {
      // Switch to complex notifications
      SimpleNotificationService().stopPolling();
      // Note: NotificationService connection should be handled by the provider
    }
  }

  Future<void> _testNotification() async {
    setState(() => _isLoading = true);

    try {
      if (_useSimpleNotifications) {
        SimpleNotificationService().sendTestNotification();
      } else {
        // Note: NotificationService should be accessed via provider
        // await NotificationService().sendTestNotification();
        _showError('Complex notifications require provider setup');
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
        content: Text(
          message,
          style: TextStyle(color: CraveVoltColors.background),
        ),
        backgroundColor: CraveVoltColors.neonLime,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.notifications),
        backgroundColor: CraveVoltColors.surface,
        foregroundColor: CraveVoltColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSettings,
          ),
        ],
      ),
      backgroundColor: CraveVoltColors.background,
      body: _isLoading
          ? Container(
              color: CraveVoltColors.background,
              child: Center(
                child: CircularProgressIndicator(
                  color: CraveVoltColors.neonLime,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification System Selection
                  Card(
                    color: CraveVoltColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: CraveVoltColors.neonLime.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notification System',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CraveVoltColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Simple Notifications
                          RadioListTile<bool>(
                            title: Text(
                              'Simple Notifications (Cloud-Friendly)',
                              style:
                                  TextStyle(color: CraveVoltColors.textPrimary),
                            ),
                            subtitle: Text(
                              'HTTP polling-based notifications. More reliable on cloud platforms. '
                              'Uses less resources but may have slight delays.',
                              style: TextStyle(
                                  color: CraveVoltColors.textSecondary),
                            ),
                            value: true,
                            groupValue: _useSimpleNotifications,
                            activeColor: CraveVoltColors.neonLime,
                            onChanged: (value) {
                              setState(() => _useSimpleNotifications = value!);
                            },
                          ),

                          // Complex Notifications
                          RadioListTile<bool>(
                            title: Text(
                              'Real-time Notifications (WebSocket)',
                              style:
                                  TextStyle(color: CraveVoltColors.textPrimary),
                            ),
                            subtitle: Text(
                              'WebSocket-based real-time notifications. Instant delivery but may have '
                              'connection issues on some cloud platforms.',
                              style: TextStyle(
                                  color: CraveVoltColors.textSecondary),
                            ),
                            value: false,
                            groupValue: _useSimpleNotifications,
                            activeColor: CraveVoltColors.neonLime,
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
                      color: CraveVoltColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: CraveVoltColors.neonLime.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Simple Notification Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: CraveVoltColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Polling Interval
                            Row(
                              children: [
                                Icon(Icons.timer,
                                    color: CraveVoltColors.neonLime),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Polling Interval: ${_pollingInterval.inSeconds} seconds',
                                    style: TextStyle(
                                        color: CraveVoltColors.textPrimary),
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
                              activeColor: CraveVoltColors.neonLime,
                              inactiveColor: CraveVoltColors.textSecondary
                                  .withOpacity(0.3),
                              onChanged: (value) {
                                setState(() {
                                  _pollingInterval =
                                      Duration(seconds: value.toInt());
                                });
                              },
                            ),

                            Text(
                              'Lower values provide faster updates but use more battery and data.',
                              style: TextStyle(
                                  color: CraveVoltColors.textSecondary),
                            ),

                            const SizedBox(height: 16),

                            // Local Notifications Toggle
                            SwitchListTile(
                              title: Text(
                                loc.showLocalNotifications,
                                style: TextStyle(
                                    color: CraveVoltColors.textPrimary),
                              ),
                              subtitle: Text(
                                loc.showLocalNotificationsDescription,
                                style: TextStyle(
                                    color: CraveVoltColors.textSecondary),
                              ),
                              value: _showLocalNotifications,
                              activeColor: CraveVoltColors.neonLime,
                              onChanged: (value) {
                                setState(() => _showLocalNotifications = value);
                              },
                            ),

                            // Notification Sounds Toggle
                            SwitchListTile(
                              title: Text(
                                loc.playNotificationSounds,
                                style: TextStyle(
                                    color: CraveVoltColors.textPrimary),
                              ),
                              subtitle: Text(
                                loc.playNotificationSoundsDescription,
                                style: TextStyle(
                                    color: CraveVoltColors.textSecondary),
                              ),
                              value: _playNotificationSounds,
                              activeColor: CraveVoltColors.neonLime,
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
                    color: CraveVoltColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: CraveVoltColors.neonLime.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.testNotifications,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CraveVoltColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _testNotification,
                            icon: const Icon(Icons.notification_add),
                            label: Text(loc.sendTestNotification),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CraveVoltColors.neonLime,
                              foregroundColor: CraveVoltColors.background,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.testNotificationDescription,
                            style:
                                TextStyle(color: CraveVoltColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Information Card
                  Card(
                    color: CraveVoltColors.neonLime.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: CraveVoltColors.neonLime.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
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
