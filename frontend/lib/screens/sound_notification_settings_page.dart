import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundNotificationSettingsPage extends ConsumerStatefulWidget {
  const SoundNotificationSettingsPage({Key? key}) : super(key: key);

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
          const SnackBar(
            content: Text('Sound settings saved successfully'),
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

  void _playTestSound() {
    // TODO: Implement sound playing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Playing test sound...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Notifications'),
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
          // New Order Notifications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restaurant_menu,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Text(
                        'New Order Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Sound'),
                    subtitle: const Text('Play sound when new orders arrive'),
                    value: _newOrderSound,
                    onChanged: (value) {
                      setState(() {
                        _newOrderSound = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Vibration'),
                    subtitle: const Text('Vibrate device for new orders'),
                    value: _vibration,
                    onChanged: (value) {
                      setState(() {
                        _vibration = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Order Status Notifications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.update, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Text(
                        'Order Status Updates',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Sound'),
                    subtitle: const Text('Play sound for order status changes'),
                    value: _orderStatusSound,
                    onChanged: (value) {
                      setState(() {
                        _orderStatusSound = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // System Notifications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Text(
                        'System Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Sound'),
                    subtitle:
                        const Text('Play sound for system alerts and errors'),
                    value: _systemSound,
                    onChanged: (value) {
                      setState(() {
                        _systemSound = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sound Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.volume_up,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Text(
                        'Sound Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sound Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedSound,
                    decoration: const InputDecoration(
                      labelText: 'Notification Sound',
                      prefixIcon: Icon(Icons.music_note),
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
                  const SizedBox(height: 16),

                  // Volume Slider
                  Row(
                    children: [
                      const Icon(Icons.volume_down),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          label: '${(_volume * 100).round()}%',
                          onChanged: (value) {
                            setState(() {
                              _volume = value;
                            });
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up),
                    ],
                  ),
                  Text(
                    'Volume: ${(_volume * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),

                  // Test Sound Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _playTestSound,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Test Sound'),
                    ),
                  ),
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
