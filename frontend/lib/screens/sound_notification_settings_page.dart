import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';

class SoundNotificationSettingsPage extends ConsumerStatefulWidget {
  const SoundNotificationSettingsPage({super.key});

  @override
  ConsumerState<SoundNotificationSettingsPage> createState() =>
      _SoundNotificationSettingsPageState();
}

class _SoundNotificationSettingsPageState
    extends ConsumerState<SoundNotificationSettingsPage> {
  bool _newOrderSound = true;
  bool _orderStatusSound = true;
  bool _systemSound = true;
  bool _vibration = true;
  double _volume = 0.8;
  String _selectedSound = 'default';

  final List<Map<String, String>> _availableSounds = [
    {'value': 'default', 'label': 'Default Notification'},
    {'value': 'chime', 'label': 'Notification Chime'},
    {'value': 'bell', 'label': 'Bell'},
    {'value': 'ding', 'label': 'Ding'},
    {'value': 'tone', 'label': 'Tone'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _newOrderSound = prefs.getBool('sound_new_order') ?? true;
        _orderStatusSound = prefs.getBool('sound_order_status') ?? true;
        _systemSound = prefs.getBool('sound_system') ?? true;
        _vibration = prefs.getBool('sound_vibration') ?? true;
        _volume = prefs.getDouble('sound_volume') ?? 0.8;
        _selectedSound = prefs.getString('sound_type') ?? 'default';
      });
    } catch (e) {
      debugPrint('Error loading sound settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_new_order', _newOrderSound);
      await prefs.setBool('sound_order_status', _orderStatusSound);
      await prefs.setBool('sound_system', _systemSound);
      await prefs.setBool('sound_vibration', _vibration);
      await prefs.setDouble('sound_volume', _volume);
      await prefs.setString('sound_type', _selectedSound);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Settings Saved',
                          style: TextStyle(
                            color: AppColors.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Sound notification preferences updated successfully',
                          style: TextStyle(
                            color:
                                AppColors.onPrimaryContainer.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.errorContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.error_rounded,
                    color: AppColors.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Save Failed',
                          style: TextStyle(
                            color: AppColors.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Failed to save settings: $e',
                          style: TextStyle(
                            color:
                                AppColors.onPrimaryContainer.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }

  void _playTestSound() {
    // TODO: Implement sound playing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.infoContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            Icon(
              Icons.play_arrow_rounded,
              color: AppColors.info,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Playing test sound...',
              style: TextStyle(
                color: AppColors.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildModernSoundCard(
    String title,
    IconData icon,
    Color accentColor,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.1),
                  accentColor.withOpacity(0.05)
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Content
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              value ? accentColor.withOpacity(0.3) : AppColors.surfaceVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? accentColor.withOpacity(0.1)
                  : AppColors.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? accentColor : AppColors.onSurfaceVariant,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: accentColor,
            activeTrackColor: accentColor.withOpacity(0.3),
            inactiveThumbColor: AppColors.surfaceVariant,
            inactiveTrackColor: AppColors.surfaceVariant.withOpacity(0.5),
          ),
        ],
      ),
    );
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
          'Sound Notifications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onPrimary,
              ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: _saveSettings,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save'),
          ),
          const SizedBox(width: 16),
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
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // New Order Notifications
            _buildModernSoundCard(
              'New Order Notifications',
              Icons.restaurant_menu,
              AppColors.primary,
              [
                _buildModernSwitchTile(
                  'Enable Sound',
                  'Play sound when new orders arrive',
                  _newOrderSound,
                  (value) => setState(() => _newOrderSound = value),
                  Icons.volume_up,
                  AppColors.primary,
                ),
                _buildModernSwitchTile(
                  'Vibration',
                  'Vibrate device for new orders',
                  _vibration,
                  (value) => setState(() => _vibration = value),
                  Icons.vibration,
                  AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Order Status Notifications
            _buildModernSoundCard(
              'Order Status Updates',
              Icons.update,
              AppColors.info,
              [
                _buildModernSwitchTile(
                  'Enable Sound',
                  'Play sound for order status changes',
                  _orderStatusSound,
                  (value) => setState(() => _orderStatusSound = value),
                  Icons.notifications_active,
                  AppColors.info,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // System Notifications
            _buildModernSoundCard(
              'System Notifications',
              Icons.settings,
              AppColors.warning,
              [
                _buildModernSwitchTile(
                  'Enable Sound',
                  'Play sound for system alerts and errors',
                  _systemSound,
                  (value) => setState(() => _systemSound = value),
                  Icons.warning,
                  AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sound Settings
            _buildModernSoundCard(
              'Sound Settings',
              Icons.volume_up,
              AppColors.secondary,
              [
                // Sound Type Dropdown
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedSound,
                    decoration: InputDecoration(
                      labelText: 'Notification Sound',
                      labelStyle: TextStyle(color: AppColors.secondary),
                      prefixIcon:
                          Icon(Icons.music_note, color: AppColors.secondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    items: _availableSounds.map((sound) {
                      return DropdownMenuItem<String>(
                        value: sound['value'],
                        child: Text(sound['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSound = value;
                        });
                      }
                    },
                  ),
                ),

                // Volume Slider
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.volume_up, color: AppColors.secondary),
                          const SizedBox(width: 12),
                          Text(
                            'Volume: ${(_volume * 100).round()}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.volume_down,
                              color: AppColors.onSurfaceVariant),
                          Expanded(
                            child: Slider(
                              value: _volume,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              activeColor: AppColors.secondary,
                              inactiveColor: AppColors.surfaceVariant,
                              onChanged: (value) {
                                setState(() {
                                  _volume = value;
                                });
                              },
                            ),
                          ),
                          Icon(Icons.volume_up,
                              color: AppColors.onSurfaceVariant),
                        ],
                      ),
                    ],
                  ),
                ),

                // Test Sound Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.secondary, AppColors.secondaryDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _playTestSound,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.black87,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Test Sound',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
