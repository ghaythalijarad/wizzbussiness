import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/design_system/typography_system.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        title: Text(
          'Notification Settings',
          style: TypographySystem.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.onPrimary,
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => _saveSettings(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
              ),
            ),
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save'),
          ),
          SizedBox(width: GoldenRatio.spacing16),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryContainer.withOpacity(0.1),
              AppColors.secondaryContainer.withOpacity(0.05),
              AppColors.background,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(GoldenRatio.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery Methods Section
                _buildNotificationSection(
                        'Delivery Methods',
                  Icons.send,
                  AppColors.primary,
                  [
                    _buildModernSwitchTile(
                      'Push Notifications',
                      'Receive notifications on your device',
                      _pushNotifications,
                      (value) => setState(() => _pushNotifications = value),
                      Icons.notifications,
                      AppColors.primary,
                    ),
                    _buildModernSwitchTile(
                      'Email Notifications',
                      'Receive notifications via email',
                      _emailNotifications,
                      (value) => setState(() => _emailNotifications = value),
                      Icons.email,
                      AppColors.secondary,
                    ),
                    _buildModernSwitchTile(
                      'SMS Notifications',
                      'Receive notifications via SMS (charges may apply)',
                      _smsNotifications,
                      (value) => setState(() => _smsNotifications = value),
                      Icons.sms,
                      AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Order Notifications Section
                _buildNotificationSection(
                  'Order Notifications',
                  Icons.shopping_cart,
                  AppColors.secondary,
                  [
                    _buildModernSwitchTile(
                      'New Orders',
                      'Get notified when new orders arrive',
                      _newOrderNotifications,
                      (value) => setState(() => _newOrderNotifications = value),
                      Icons.add_shopping_cart,
                      AppColors.primary,
                    ),
                    _buildModernSwitchTile(
                      'Order Status Updates',
                      'Get notified when order status changes',
                      _orderStatusNotifications,
                      (value) =>
                          setState(() => _orderStatusNotifications = value),
                      Icons.update,
                      AppColors.secondary,
                    ),
                    _buildModernSwitchTile(
                      'Payment Notifications',
                      'Get notified about payment updates',
                      _paymentNotifications,
                      (value) => setState(() => _paymentNotifications = value),
                      Icons.payment,
                      AppColors.primary,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withOpacity(0.04),
            blurRadius: GoldenRatio.spacing20,
            offset: Offset(0, GoldenRatio.sm),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(GoldenRatio.spacing20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withOpacity(0.1),
                  iconColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(GoldenRatio.radiusXl),
                topRight: Radius.circular(GoldenRatio.radiusXl),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(GoldenRatio.spacing12),
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: GoldenRatio.spacing20,
                  ),
                ),
                SizedBox(width: GoldenRatio.spacing16),
                Text(
                  title,
                  style: TypographySystem.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(GoldenRatio.spacing20),
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
      margin: EdgeInsets.only(bottom: GoldenRatio.spacing16),
      padding: EdgeInsets.all(GoldenRatio.spacing20),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        border: Border.all(
          color: iconColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(GoldenRatio.sm),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(GoldenRatio.sm),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: GoldenRatio.spacing20,
            ),
          ),
          SizedBox(width: GoldenRatio.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TypographySystem.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                SizedBox(height: GoldenRatio.xs),
                Text(
                  subtitle,
                  style: TypographySystem.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
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
            inactiveThumbColor: AppColors.onSurfaceVariant,
            inactiveTrackColor: AppColors.surfaceVariant,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.black87,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Notification settings saved successfully',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.error_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to save settings: $e',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}
