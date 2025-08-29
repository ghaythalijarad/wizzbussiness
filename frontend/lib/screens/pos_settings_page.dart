import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/design_system/typography_system.dart';

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
          SnackBar(
            content: Text('POS settings saved successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save POS settings: $e'),
            backgroundColor: AppColors.error,
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
            backgroundColor: isSuccess ? AppColors.primary : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection test failed: $e'),
            backgroundColor: AppColors.error,
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
      backgroundColor: AppColors.backgroundVariant,
      appBar: AppBar(
        title: Text(loc.posSettings),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _savePosSettings,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(GoldenRatio.spacing16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enable POS Integration
                    Card(
                      color: AppColors.surface,
                      elevation: 2,
                      child: SwitchListTile(
                        title: Text(
                          'Enable POS Integration',
                          style: TypographySystem.bodyLarge,
                        ),
                        subtitle: Text(
                          'Connect with your point of sale system',
                          style: TypographySystem.bodyMedium.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        value: _isEnabled,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() {
                            _isEnabled = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: GoldenRatio.spacing16),

                    if (_isEnabled) ...[
                      // System Type Dropdown
                      Card(
                        color: AppColors.surface,
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(GoldenRatio.spacing16),
                          child: DropdownButtonFormField<String>(
                            value: _systemType,
                            decoration: InputDecoration(
                              labelText: 'POS System Type',
                              hintText: 'Select your POS system',
                              prefixIcon: Icon(Icons.computer,
                                  color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(GoldenRatio.radiusMd),
                              ),
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
                        ),
                      ),
                      SizedBox(height: GoldenRatio.spacing16),

                      // API Configuration Card
                      Card(
                        color: AppColors.surface,
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(GoldenRatio.spacing16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'API Configuration',
                                style: TypographySystem.titleMedium.copyWith(
                                  color: AppColors.onSurface,
                                ),
                              ),
                              SizedBox(height: GoldenRatio.spacing12),

                              // API Endpoint
                              TextFormField(
                                controller: _apiEndpointController,
                                decoration: InputDecoration(
                                  labelText: 'API Endpoint',
                                  hintText: 'https://api.yourpos.com/v1',
                                  prefixIcon: Icon(Icons.link,
                                      color: AppColors.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        GoldenRatio.radiusMd),
                                  ),
                                ),
                                validator: (value) {
                                  if (_isEnabled &&
                                      (value == null || value.isEmpty)) {
                                    return 'API endpoint is required when POS is enabled';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: GoldenRatio.spacing16),

                              // API Key
                              TextFormField(
                                controller: _apiKeyController,
                                decoration: InputDecoration(
                                  labelText: 'API Key',
                                  hintText: 'Your POS system API key',
                                  prefixIcon:
                                      Icon(Icons.key, color: AppColors.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        GoldenRatio.radiusMd),
                                  ),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (_isEnabled &&
                                      (value == null || value.isEmpty)) {
                                    return 'API key is required when POS is enabled';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: GoldenRatio.spacing16),

                              // Location ID (if applicable)
                              TextFormField(
                                controller: _locationIdController,
                                decoration: InputDecoration(
                                  labelText: 'Location ID (Optional)',
                                  hintText: 'Location or store ID',
                                  prefixIcon: Icon(Icons.location_on,
                                      color: AppColors.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        GoldenRatio.radiusMd),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: GoldenRatio.spacing20),

                      // Settings Card
                      Card(
                        color: AppColors.surface,
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(GoldenRatio.spacing16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'POS Configuration',
                                style: TypographySystem.titleMedium.copyWith(
                                  color: AppColors.onSurface,
                                ),
                              ),
                              SizedBox(height: GoldenRatio.spacing12),

                              // Test Mode Switch
                              SwitchListTile(
                                title: Text(
                                  'Test Mode',
                                  style: TypographySystem.bodyLarge,
                                ),
                                subtitle: Text(
                                  'Use sandbox/test environment',
                                  style: TypographySystem.bodyMedium.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                value: _testMode,
                                activeColor: AppColors.primary,
                                onChanged: (value) {
                                  setState(() {
                                    _testMode = value;
                                  });
                                },
                              ),

                              // Auto Send Orders
                              SwitchListTile(
                                title: Text(
                                  'Auto Send Orders',
                                  style: TypographySystem.bodyLarge,
                                ),
                                subtitle: Text(
                                  'Automatically send accepted orders to POS',
                                  style: TypographySystem.bodyMedium.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                value: _autoSendOrders,
                                activeColor: AppColors.primary,
                                onChanged: (value) {
                                  setState(() {
                                    _autoSendOrders = value;
                                  });
                                },
                              ),

                              // Auto Accept Orders
                              SwitchListTile(
                                title: Text(
                                  'Auto Accept Orders',
                                  style: TypographySystem.bodyLarge,
                                ),
                                subtitle: Text(
                                  'Automatically accept all incoming orders',
                                  style: TypographySystem.bodyMedium.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                value: _autoAcceptOrders,
                                activeColor: AppColors.primary,
                                onChanged: (value) {
                                  setState(() {
                                    _autoAcceptOrders = value;
                                  });
                                },
                              ),

                              // Timeout Settings
                              ListTile(
                                title: Text(
                                  'Connection Timeout',
                                  style: TypographySystem.bodyLarge,
                                ),
                                subtitle: Text(
                                  '$_timeoutSeconds seconds',
                                  style: TypographySystem.bodyMedium.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                trailing: SizedBox(
                                  width: 100,
                                  child: Slider(
                                    value: _timeoutSeconds.toDouble(),
                                    min: 10,
                                    max: 120,
                                    divisions: 11,
                                    label: '$_timeoutSeconds s',
                                    activeColor: AppColors.primary,
                                    onChanged: (value) {
                                      setState(() {
                                        _timeoutSeconds = value.round();
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: GoldenRatio.spacing20),

                      // Action Buttons
                      Card(
                        color: AppColors.surface,
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(GoldenRatio.spacing16),
                          child: Column(
                            children: [
                              // Test Connection Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _testConnection,
                                  icon: Icon(Icons.wifi_protected_setup,
                                      color: AppColors.primary),
                                  label: Text(
                                    'Test Connection',
                                    style: TypographySystem.labelLarge.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        vertical: GoldenRatio.spacing16),
                                    side: BorderSide(color: AppColors.primary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          GoldenRatio.radiusMd),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: GoldenRatio.spacing16),

                              // Save Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _savePosSettings,
                                  icon: Icon(Icons.save,
                                      color: AppColors.onPrimary),
                                  label: Text(
                                    'Save Settings',
                                    style: TypographySystem.labelLarge.copyWith(
                                      color: AppColors.onPrimary,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                    padding: EdgeInsets.symmetric(
                                        vertical: GoldenRatio.spacing16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          GoldenRatio.radiusMd),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
