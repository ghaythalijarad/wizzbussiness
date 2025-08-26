import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class PosSettingsPage extends ConsumerStatefulWidget {
  final Business business;

  const PosSettingsPage({Key? key, required this.business}) : super(key: key);

  @override
  ConsumerState<PosSettingsPage> createState() => _PosSettingsPageState();
}

class _PosSettingsPageState extends ConsumerState<PosSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiEndpointController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _locationIdController = TextEditingController();

  bool _isLoading = false;
  bool _isEnabled = false;
  bool _testMode = false;
  bool _autoSendOrders = false;
  bool _autoAcceptOrders = true;
  String _systemType = 'genericApi';
  int _timeoutSeconds = 30;

  final List<Map<String, String>> _systemTypes = [
    {'value': 'genericApi', 'label': 'Generic API'},
    {'value': 'square', 'label': 'Square POS'},
    {'value': 'toast', 'label': 'Toast POS'},
    {'value': 'clover', 'label': 'Clover'},
    {'value': 'shopify', 'label': 'Shopify'},
    {'value': 'woocommerce', 'label': 'WooCommerce'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPosSettings();
  }

  @override
  void dispose() {
    _apiEndpointController.dispose();
    _apiKeyController.dispose();
    _locationIdController.dispose();
    super.dispose();
  }

  Future<void> _loadPosSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final settings = await apiService.getPosSettings(widget.business.id);
      
      if (mounted) {
        setState(() {
          _apiEndpointController.text = settings['apiEndpoint'] ?? '';
          _apiKeyController.text = settings['apiKey'] ?? '';
          _locationIdController.text = settings['locationId'] ?? '';
          _isEnabled = settings['enabled'] ?? false;
          _testMode = settings['testMode'] ?? false;
          _autoSendOrders = settings['autoSendOrders'] ?? false;
          _autoAcceptOrders = settings['autoAcceptOrders'] ?? true;
          _systemType = settings['systemType'] ?? 'genericApi';
          _timeoutSeconds = settings['timeoutSeconds'] ?? 30;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load POS settings: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePosSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final settings = {
        'apiEndpoint': _apiEndpointController.text,
        'apiKey': _apiKeyController.text,
        'locationId': _locationIdController.text,
        'enabled': _isEnabled,
        'testMode': _testMode,
        'autoSendOrders': _autoSendOrders,
        'autoAcceptOrders': _autoAcceptOrders,
        'systemType': _systemType,
        'timeoutSeconds': _timeoutSeconds,
      };

      await apiService.updatePosSettings(widget.business.id, settings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('POS settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save POS settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final testConfig = {
        'apiEndpoint': _apiEndpointController.text,
        'apiKey': _apiKeyController.text,
        'locationId': _locationIdController.text,
        'systemType': _systemType,
      };

      final result =
          await apiService.testPosConnection(widget.business.id, testConfig);
      
      if (mounted) {
        final isSuccess = result['success'] ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSuccess
                ? 'Connection test successful!'
                : 'Connection test failed: ${result['message'] ?? 'Unknown error'}'),
            backgroundColor: isSuccess ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.posSettings),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _savePosSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enable POS Integration
                    SwitchListTile(
                      title: const Text('Enable POS Integration'),
                      subtitle:
                          const Text('Connect with your point of sale system'),
                      value: _isEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    if (_isEnabled) ...[
                      // System Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _systemType,
                        decoration: const InputDecoration(
                          labelText: 'POS System Type',
                          hintText: 'Select your POS system',
                          prefixIcon: Icon(Icons.computer),
                        ),
                        items: _systemTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type['value'],
                            child: Text(type['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _systemType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // API Endpoint
                      TextFormField(
                        controller: _apiEndpointController,
                        decoration: const InputDecoration(
                          labelText: 'API Endpoint',
                          hintText: 'https://api.yourpos.com/v1',
                          prefixIcon: Icon(Icons.link),
                        ),
                        validator: (value) {
                          if (_isEnabled && (value == null || value.isEmpty)) {
                            return 'API endpoint is required when POS is enabled';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // API Key
                      TextFormField(
                        controller: _apiKeyController,
                        decoration: const InputDecoration(
                          labelText: 'API Key',
                          hintText: 'Your POS system API key',
                          prefixIcon: Icon(Icons.key),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (_isEnabled && (value == null || value.isEmpty)) {
                            return 'API key is required when POS is enabled';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Location ID (if applicable)
                      TextFormField(
                        controller: _locationIdController,
                        decoration: const InputDecoration(
                          labelText: 'Location ID (Optional)',
                          hintText: 'Location or store ID',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Test Mode Switch
                      SwitchListTile(
                        title: const Text('Test Mode'),
                        subtitle: const Text('Use sandbox/test environment'),
                        value: _testMode,
                        onChanged: (value) {
                          setState(() {
                            _testMode = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Auto Send Orders
                      SwitchListTile(
                        title: const Text('Auto Send Orders'),
                        subtitle: const Text(
                            'Automatically send accepted orders to POS'),
                        value: _autoSendOrders,
                        onChanged: (value) {
                          setState(() {
                            _autoSendOrders = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Auto Accept Orders
                      SwitchListTile(
                        title: const Text('Auto Accept Orders'),
                        subtitle: const Text(
                            'Automatically accept all incoming orders'),
                        value: _autoAcceptOrders,
                        onChanged: (value) {
                          setState(() {
                            _autoAcceptOrders = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Timeout Settings
                      ListTile(
                        title: const Text('Connection Timeout'),
                        subtitle: Text('$_timeoutSeconds seconds'),
                        trailing: SizedBox(
                          width: 100,
                          child: Slider(
                            value: _timeoutSeconds.toDouble(),
                            min: 10,
                            max: 120,
                            divisions: 11,
                            label: '$_timeoutSeconds s',
                            onChanged: (value) {
                              setState(() {
                                _timeoutSeconds = value.round();
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Test Connection Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _testConnection,
                          icon: const Icon(Icons.wifi_protected_setup),
                          label: const Text('Test Connection'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _savePosSettings,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Settings'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
