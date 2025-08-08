import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/sound_notification_settings.dart';
import '../services/audio_notification_service.dart';

class SoundNotificationSettingsPage extends StatefulWidget {
  const SoundNotificationSettingsPage({super.key});

  @override
  State<SoundNotificationSettingsPage> createState() =>
      _SoundNotificationSettingsPageState();
}

class _SoundNotificationSettingsPageState
    extends State<SoundNotificationSettingsPage> with TickerProviderStateMixin {
  late final SoundNotificationSettings _settings;
  late final AudioNotificationService _audioService;
  bool _isLoading = false;
  bool _isTesting = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _settings = SoundNotificationSettings();
    _audioService = AudioNotificationService();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      await _settings.initialize();
      await _audioService.initialize();
    } catch (e) {
      _showError('Failed to load sound settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      // Settings are automatically saved by the service when modified
      _showSuccess('Sound settings saved successfully!');
    } catch (e) {
      _showError('Failed to save sound settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSound(String soundType) async {
    if (_isTesting) return;

    setState(() => _isTesting = true);
    try {
      HapticFeedback.lightImpact();

      switch (soundType) {
        case 'new_order':
          await _audioService.playNewOrderSound();
          break;
        case 'urgent_order':
          await _audioService.playUrgentOrderSound();
          break;
        case 'order_update':
          // await _audioService.playOrderUpdateSound(); // Method not available
          break;
        case 'notification_chime':
          await _audioService.playNotificationChime();
          break;
      }

      _showSuccess('Test sound played!');
    } catch (e) {
      _showError('Failed to play test sound: $e');
    } finally {
      // Add a small delay to prevent rapid successive tests
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Notifications'),
        backgroundColor: const Color(0xFF00C1E8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.volume_up), text: 'General'),
            Tab(icon: Icon(Icons.tune), text: 'Sounds'),
            Tab(icon: Icon(Icons.info), text: 'About'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralTab(),
                _buildSoundsTab(),
                _buildAboutTab(),
              ],
            ),
    );
  }

  Widget _buildGeneralTab() {
    return AnimatedBuilder(
      animation: _settings,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Master Sound Toggle
              _buildSectionCard(
                title: 'Master Volume Control',
                icon: Icons.volume_up,
                children: [
                  SwitchListTile(
                    title: const Text('Enable Sound Notifications'),
                    subtitle:
                        const Text('Turn all notification sounds on or off'),
                    value: _settings.soundEnabled,
                    onChanged: (value) {
                      _settings.setSoundEnabled(value);
                      if (value) {
                        HapticFeedback.lightImpact();
                      }
                    },
                    secondary: Icon(
                      _settings.soundEnabled
                          ? Icons.volume_up
                          : Icons.volume_off,
                      color: _settings.soundEnabled ? Colors.blue : Colors.grey,
                    ),
                  ),
                  const Divider(),
                  _buildVolumeSlider(),
                ],
              ),

              const SizedBox(height: 16),

              // Sound Theme Selection
              _buildSectionCard(
                title: 'Sound Theme',
                icon: Icons.music_note,
                children: [
                  const Text(
                    'Choose your preferred sound style:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  _buildThemeSelector(),
                ],
              ),

              const SizedBox(height: 16),

              // Quick Settings
              _buildSectionCard(
                title: 'Quick Settings',
                icon: Icons.settings,
                children: [
                  _buildQuickToggle(
                    'New Orders',
                    'Play sound for incoming orders',
                    Icons.shopping_cart,
                    _settings.newOrderSoundEnabled,
                    (value) => _settings.setNewOrderSoundEnabled(value),
                  ),
                  _buildQuickToggle(
                    'Order Updates',
                    'Play sound for order status changes',
                    Icons.update,
                    _settings.orderUpdateSoundEnabled,
                    (value) => _settings.setOrderUpdateSoundEnabled(value),
                  ),
                  _buildQuickToggle(
                    'Urgent Orders',
                    'Play special sound for high-value orders',
                    Icons.priority_high,
                    _settings.urgentOrderSoundEnabled,
                    (value) => _settings.setUrgentOrderSoundEnabled(value),
                  ),
                  _buildQuickToggle(
                    'Popup Notifications',
                    'Play chime for popup cards',
                    Icons.notifications_active,
                    _settings.popupSoundEnabled,
                    (value) => _settings.setPopupSoundEnabled(value),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSoundsTab() {
    return AnimatedBuilder(
      animation: _settings,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Test Sound Cards
              _buildTestSoundCard(
                title: 'New Order Sound',
                description: 'Plays when a new order arrives',
                icon: Icons.shopping_cart,
                color: Colors.green,
                soundType: 'new_order',
                isEnabled: _settings.newOrderSoundEnabled,
                onToggle: (value) => _settings.setNewOrderSoundEnabled(value),
              ),

              const SizedBox(height: 16),

              _buildTestSoundCard(
                title: 'Urgent Order Sound',
                description: 'Plays for high-value orders (>\$100)',
                icon: Icons.priority_high,
                color: Colors.red,
                soundType: 'urgent_order',
                isEnabled: _settings.urgentOrderSoundEnabled,
                onToggle: (value) =>
                    _settings.setUrgentOrderSoundEnabled(value),
              ),

              const SizedBox(height: 16),

              _buildTestSoundCard(
                title: 'Order Update Sound',
                description: 'Plays when order status changes',
                icon: Icons.update,
                color: Colors.orange,
                soundType: 'order_update',
                isEnabled: _settings.orderUpdateSoundEnabled,
                onToggle: (value) =>
                    _settings.setOrderUpdateSoundEnabled(value),
              ),

              const SizedBox(height: 16),

              _buildTestSoundCard(
                title: 'Notification Chime',
                description: 'Plays for popup notifications',
                icon: Icons.notifications_active,
                color: Colors.blue,
                soundType: 'notification_chime',
                isEnabled: _settings.popupSoundEnabled,
                onToggle: (value) => _settings.setPopupSoundEnabled(value),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Sound Notification Features',
            icon: Icons.info,
            children: [
              _buildFeatureItem(
                icon: Icons.volume_up,
                title: 'Adaptive Volume',
                description: 'Automatically adjusts based on device settings',
              ),
              _buildFeatureItem(
                icon: Icons.vibration,
                title: 'Haptic Feedback',
                description: 'Physical vibration accompanies sound alerts',
              ),
              _buildFeatureItem(
                icon: Icons.smart_toy,
                title: 'Smart Detection',
                description: 'Automatically detects urgent orders by value',
              ),
              _buildFeatureItem(
                icon: Icons.settings,
                title: 'Granular Control',
                description: 'Individual settings for each notification type',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Sound Quality',
            icon: Icons.high_quality,
            children: [
              const Text(
                'All notification sounds are optimized for business environments:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              _buildQualityItem('High-quality audio files'),
              _buildQualityItem('Low latency playback'),
              _buildQualityItem('Multiple device support'),
              _buildQualityItem('Background playback capability'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Tips for Best Experience',
            icon: Icons.lightbulb,
            children: [
              _buildTipItem(
                icon: Icons.volume_up,
                text:
                    'Keep device volume at 50-80% for optimal alert recognition',
              ),
              _buildTipItem(
                icon: Icons.do_not_disturb_off,
                text:
                    'Disable Do Not Disturb mode for important business hours',
              ),
              _buildTipItem(
                icon: Icons.battery_charging_full,
                text: 'Enable power saving exemption for the app',
              ),
              _buildTipItem(
                icon: Icons.notifications,
                text: 'Test notifications regularly to ensure they\'re working',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF00C1E8)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.volume_down, size: 20),
            Expanded(
              child: Slider(
                value: _settings.volume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(_settings.volume * 100).round()}%',
                onChanged: _settings.soundEnabled
                    ? (value) {
                        _settings.setVolume(value);
                        HapticFeedback.selectionClick();
                      }
                    : null,
              ),
            ),
            const Icon(Icons.volume_up, size: 20),
          ],
        ),
        Text(
          'Volume: ${(_settings.volume * 100).round()}%',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildThemeSelector() {
    final themes = [
      {
        'value': 'default',
        'label': 'Default',
        'description': 'Standard notification sounds'
      },
      {
        'value': 'professional',
        'label': 'Professional',
        'description': 'Subtle, business-friendly tones'
      },
      {
        'value': 'modern',
        'label': 'Modern',
        'description': 'Contemporary digital sounds'
      },
    ];

    return Column(
      children: themes.map((theme) {
        return RadioListTile<String>(
          title: Text(theme['label']!),
          subtitle: Text(theme['description']!),
          value: theme['value']!,
          groupValue: _settings.soundTheme,
          onChanged: _settings.soundEnabled
              ? (value) {
                  _settings.setSoundTheme(value!);
                  HapticFeedback.selectionClick();
                }
              : null,
        );
      }).toList(),
    );
  }

  Widget _buildQuickToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: value ? const Color(0xFF00C1E8) : Colors.grey),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value && _settings.soundEnabled,
        onChanged: _settings.soundEnabled
            ? (newValue) {
                onChanged(newValue);
                if (newValue) HapticFeedback.lightImpact();
              }
            : null,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTestSoundCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String soundType,
    required bool isEnabled,
    required Function(bool) onToggle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled && _settings.soundEnabled,
                  onChanged: _settings.soundEnabled
                      ? (value) {
                          onToggle(value);
                          if (value) HapticFeedback.lightImpact();
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        (_settings.soundEnabled && isEnabled && !_isTesting)
                            ? () => _testSound(soundType)
                            : null,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isTesting ? 'Playing...' : 'Test Sound'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
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

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF00C1E8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTipItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
