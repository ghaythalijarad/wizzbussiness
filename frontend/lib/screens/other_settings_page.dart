import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class OtherSettingsPage extends ConsumerStatefulWidget {
  final Business business;

  const OtherSettingsPage({Key? key, required this.business}) : super(key: key);

  @override
  ConsumerState<OtherSettingsPage> createState() => _OtherSettingsPageState();
}

class _OtherSettingsPageState extends ConsumerState<OtherSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _countryController = TextEditingController();
  final _streetController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  bool _isLoading = false;
  bool _enableDelivery = true;
  bool _enablePickup = true;
  double _deliveryRadius = 5.0;
  double _minimumOrderAmount = 10.0;
  double _deliveryFee = 2.50;

  @override
  void initState() {
    super.initState();
    _loadLocationSettings();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _countryController.dispose();
    _streetController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load business data
      final business = widget.business;
      _addressController.text = business.address ?? '';
      _cityController.text = business.address ?? '';
      _districtController.text = '';
      _countryController.text = 'Iraq';
      _streetController.text = '';
      _latitudeController.text = business.latitude?.toString() ?? '';
      _longitudeController.text = business.longitude?.toString() ?? '';

      // Try to load additional location settings from API
      final apiService = ApiService();
      try {
        final settings =
            await apiService.getBusinessLocationSettings(business.id);
        if (mounted) {
          setState(() {
            _enableDelivery = settings['enableDelivery'] ?? true;
            _enablePickup = settings['enablePickup'] ?? true;
            _deliveryRadius = (settings['deliveryRadius'] ?? 5.0).toDouble();
            _minimumOrderAmount =
                (settings['minimumOrderAmount'] ?? 10.0).toDouble();
            _deliveryFee = (settings['deliveryFee'] ?? 2.50).toDouble();
          });
        }
      } catch (e) {
        // If location settings don't exist, use defaults
        debugPrint('No existing location settings found, using defaults');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load location settings: $e'),
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

  Future<void> _saveLocationSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final settings = {
        'address': _addressController.text,
        'city': _cityController.text,
        'district': _districtController.text,
        'country': _countryController.text,
        'street': _streetController.text,
        'latitude': double.tryParse(_latitudeController.text),
        'longitude': double.tryParse(_longitudeController.text),
        'enableDelivery': _enableDelivery,
        'enablePickup': _enablePickup,
        'deliveryRadius': _deliveryRadius,
        'minimumOrderAmount': _minimumOrderAmount,
        'deliveryFee': _deliveryFee,
      };

      await apiService.updateBusinessLocationSettings(
          widget.business.id, settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save location settings: $e'),
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

  void _getCurrentLocation() async {
    // TODO: Implement location fetching using location services
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Getting current location...'),
        duration: Duration(seconds: 2),
      ),
    );

    // For now, set sample coordinates for Baghdad
    setState(() {
      _latitudeController.text = '33.3152';
      _longitudeController.text = '44.3661';
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.locationSettings),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveLocationSettings,
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
                    // Business Address Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: Theme.of(context).primaryColor),
                                const SizedBox(width: 12),
                                const Text(
                                  'Business Address',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Street Address',
                                hintText: 'Enter your business address',
                                prefixIcon: Icon(Icons.home),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your business address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _cityController,
                                    decoration: const InputDecoration(
                                      labelText: 'City',
                                      prefixIcon: Icon(Icons.location_city),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'City required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _districtController,
                                    decoration: const InputDecoration(
                                      labelText: 'District',
                                      prefixIcon: Icon(Icons.map),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _countryController,
                              decoration: const InputDecoration(
                                labelText: 'Country',
                                prefixIcon: Icon(Icons.public),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter country';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // GPS Coordinates Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.gps_fixed,
                                    color: Theme.of(context).primaryColor),
                                const SizedBox(width: 12),
                                const Text(
                                  'GPS Coordinates',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _latitudeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Latitude',
                                      hintText: '33.3152',
                                      prefixIcon: Icon(Icons.navigation),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _longitudeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Longitude',
                                      hintText: '44.3661',
                                      prefixIcon: Icon(Icons.navigation),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _getCurrentLocation,
                                icon: const Icon(Icons.my_location),
                                label: const Text('Get Current Location'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Service Options Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.delivery_dining,
                                    color: Theme.of(context).primaryColor),
                                const SizedBox(width: 12),
                                const Text(
                                  'Service Options',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Enable Delivery'),
                              subtitle: const Text(
                                  'Offer delivery service to customers'),
                              value: _enableDelivery,
                              onChanged: (value) {
                                setState(() {
                                  _enableDelivery = value;
                                });
                              },
                            ),
                            SwitchListTile(
                              title: const Text('Enable Pickup'),
                              subtitle: const Text(
                                  'Allow customers to pick up orders'),
                              value: _enablePickup,
                              onChanged: (value) {
                                setState(() {
                                  _enablePickup = value;
                                });
                              },
                            ),

                            if (_enableDelivery) ...[
                              const SizedBox(height: 16),

                              // Delivery Radius
                              Text(
                                'Delivery Radius: ${_deliveryRadius.toStringAsFixed(1)} km',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Slider(
                                value: _deliveryRadius,
                                min: 1.0,
                                max: 50.0,
                                divisions: 49,
                                label:
                                    '${_deliveryRadius.toStringAsFixed(1)} km',
                                onChanged: (value) {
                                  setState(() {
                                    _deliveryRadius = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),

                              // Minimum Order Amount
                              TextFormField(
                                initialValue: _minimumOrderAmount.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Minimum Order Amount',
                                  prefixIcon: Icon(Icons.attach_money),
                                  suffixText: 'IQD',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  _minimumOrderAmount =
                                      double.tryParse(value) ?? 10.0;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Delivery Fee
                              TextFormField(
                                initialValue: _deliveryFee.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Delivery Fee',
                                  prefixIcon: Icon(Icons.local_shipping),
                                  suffixText: 'IQD',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  _deliveryFee = double.tryParse(value) ?? 2.50;
                                },
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
                        onPressed: _isLoading ? null : _saveLocationSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Location Settings'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
