import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/location_settings_widget.dart';

class OtherSettingsPage extends ConsumerStatefulWidget {
  final Business business;

  const OtherSettingsPage({Key? key, required this.business}) : super(key: key);

  @override
  ConsumerState<OtherSettingsPage> createState() => _OtherSettingsPageState();
}

class _OtherSettingsPageState extends ConsumerState<OtherSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _countryController = TextEditingController();
  final _streetController = TextEditingController();

  bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  String? _address;

  @override
  void initState() {
    super.initState();
    _loadLocationSettings();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _districtController.dispose();
    _countryController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load business data
      final business = widget.business;
      _latitude = business.latitude;
      _longitude = business.longitude;

      // Extract data directly from business properties - no parsing needed!
      String city = business.city ?? '';
      String district = business.district ?? '';
      String street = business.street ?? '';
      String country = business.country ?? 'Iraq';
      String mainAddress = business.address ?? '';

      // If we don't have a full address but have components, build it
      if (mainAddress.isEmpty && (city.isNotEmpty || district.isNotEmpty || street.isNotEmpty)) {
        final addressParts = [street, district, city, country]
            .where((part) => part.isNotEmpty)
            .toList();
        mainAddress = addressParts.join(', ');
      }

      // Set the form fields with extracted data
      setState(() {
        _cityController.text = city;
        _districtController.text = district;
        _streetController.text = street;
        _countryController.text = country;
        _address = mainAddress.isNotEmpty ? mainAddress : null;
      });

      debugPrint('Location data loaded from Business model:');
      debugPrint('  City: $city');
      debugPrint('  District: $district');
      debugPrint('  Street: $street');
      debugPrint('  Country: $country');
      debugPrint('  Full Address: $mainAddress');
      debugPrint('  Coordinates: $_latitude, $_longitude');

      // Try to load additional location settings from API
      final apiService = ApiService();
      try {
        final settings = await apiService.getBusinessLocationSettings(business.id);
        if (mounted && settings['settings'] != null) {
          final locationData = settings['settings'];
          
          setState(() {
            // Update GPS coordinates from location settings
            _latitude = locationData['latitude']?.toDouble() ?? _latitude;
            _longitude = locationData['longitude']?.toDouble() ?? _longitude;
            
            // Override with API data if available and more specific
            if (locationData['city']?.toString().isNotEmpty == true) {
              _cityController.text = locationData['city'].toString();
            }
            if (locationData['district']?.toString().isNotEmpty == true) {
              _districtController.text = locationData['district'].toString();
            }
            if (locationData['street']?.toString().isNotEmpty == true) {
              _streetController.text = locationData['street'].toString();
            }
            if (locationData['country']?.toString().isNotEmpty == true) {
              _countryController.text = locationData['country'].toString();
            }
            
            // Update the address variable for LocationSettingsWidget based on API data
            if (locationData['address']?.toString().isNotEmpty == true) {
              _address = locationData['address'].toString();
            }
          });
        }
      } catch (e) {
        // If location settings don't exist, continue with business data
        debugPrint('No additional location settings found: $e');
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
      
      // Create comprehensive location settings object
      final settings = {
        // Individual address components for mapping
        'city': _cityController.text.trim(),
        'district': _districtController.text.trim(),
        'country': _countryController.text.trim(),
        'street': _streetController.text.trim(),
        
        // GPS coordinates
        'latitude': _latitude,
        'longitude': _longitude,
        
        // Build address string for backward compatibility
        'address': _buildAddressString(),
        
        // Additional metadata
        'updated_at': DateTime.now().toIso8601String(),
        
        // Also include the DynamoDB format for backward compatibility
        'address_components': {
          'city': {'S': _cityController.text.trim()},
          'district': {'S': _districtController.text.trim()},
          'country': {'S': _countryController.text.trim()},
          'street': {'S': _streetController.text.trim()},
        },
      };

      // Remove empty fields to keep the data clean
      settings.removeWhere((key, value) => 
        value == null || (value is String && value.isEmpty));

      // Also remove empty nested components
      if (settings['address_components'] != null) {
        final components = settings['address_components'] as Map<String, dynamic>;
        components.removeWhere((key, value) {
          if (value is Map<String, dynamic> && value['S'] is String) {
            return (value['S'] as String).isEmpty;
          }
          return false;
        });
        
        if (components.isEmpty) {
          settings.remove('address_components');
        }
      }

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
  
  /// Build a readable address string from individual components
  String _buildAddressString() {
    // Build from components
    final parts = <String>[];
    
    if (_streetController.text.trim().isNotEmpty) {
      parts.add(_streetController.text.trim());
    }
    if (_districtController.text.trim().isNotEmpty) {
      parts.add(_districtController.text.trim());
    }
    if (_cityController.text.trim().isNotEmpty) {
      parts.add(_cityController.text.trim());
    }
    if (_countryController.text.trim().isNotEmpty) {
      parts.add(_countryController.text.trim());
    }
    
    return parts.join(', ');
  }

  void _onLocationChanged(double? latitude, double? longitude, String? address) {
    setState(() {
      _latitude = latitude;
      _longitude = longitude;
      _address = address;
    });
    
    // If we got a new address from GPS, try to parse it and update form fields
    if (address != null && address.isNotEmpty && 
        address != 'Address not available (stub implementation)' &&
        address != 'Address not available') {
      
      final addressParts = _parseAddress(address);
      
      setState(() {
        // Only update fields that are currently empty to avoid overwriting user input
        if (_cityController.text.isEmpty && addressParts['city'] != null) {
          _cityController.text = addressParts['city']!;
        }
        
        if (_districtController.text.isEmpty && addressParts['district'] != null) {
          _districtController.text = addressParts['district']!;
        }
        
        if (_streetController.text.isEmpty && addressParts['street'] != null) {
          _streetController.text = addressParts['street']!;
        }
        
        if (_countryController.text == 'Iraq' && addressParts['country'] != null) {
          _countryController.text = addressParts['country']!;
        }
      });
    }
  }

  /// Simple address parsing to extract components
  Map<String, String?> _parseAddress(String address) {
    final Map<String, String?> components = {
      'street': null,
      'city': null,
      'district': null,
      'country': null,
    };
    
    if (address.isEmpty) return components;
    
    // Split address by common separators
    final parts = address.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    
    if (parts.isNotEmpty) {
      // First part is usually street address
      components['street'] = parts[0];
      
      // Look for common Iraqi city names
      for (final part in parts) {
        final lowerPart = part.toLowerCase();
        if (_isKnownCity(lowerPart)) {
          components['city'] = part;
          break;
        }
      }
      
      // If more than one part, use last part as country (if it looks like a country)
      if (parts.length > 1) {
        final lastPart = parts.last.toLowerCase();
        if (_isKnownCountry(lastPart)) {
          components['country'] = parts.last;
        }
      }
      
      // Try to identify district (usually middle parts that aren't city or country)
      for (final part in parts) {
        if (part != components['street'] && 
            part != components['city'] && 
            part != components['country']) {
          components['district'] = part;
          break;
        }
      }
    }
    
    return components;
  }
  
  /// Check if a string contains a known city name
  bool _isKnownCity(String text) {
    final knownCities = [
      'baghdad', 'basra', 'mosul', 'erbil', 'najaf', 'karbala', 
      'kirkuk', 'sulaymaniyah', 'ramadi', 'fallujah', 'tikrit',
      'amarah', 'nasiriyah', 'kut', 'hilla', 'diwaniyah',
      'samarra', 'duhok', 'zakho', 'halabja'
    ];
    return knownCities.any((city) => text.contains(city));
  }
  
  /// Check if a string contains a known country name
  bool _isKnownCountry(String text) {
    final knownCountries = ['iraq', 'iraqi', 'kurdistan'];
    return knownCountries.any((country) => text.contains(country));
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
                            const SizedBox(height: 20),
                            
                            // Address Components Section
                            const Text(
                              'Address Components',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 16),
                            // Street Name Field (for mapping)
                            TextFormField(
                              controller: _streetController,
                              decoration: const InputDecoration(
                                labelText: 'Street Name',
                                hintText: 'Enter specific street name for mapping',
                                prefixIcon: Icon(Icons.streetview),
                                helperText: 'Street name used for location mapping and delivery',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Street name is required for mapping';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // GPS Location Section using LocationSettingsWidget
                    LocationSettingsWidget(
                      initialLatitude: _latitude,
                      initialLongitude: _longitude,
                      initialAddress: _address,
                      onLocationChanged: _onLocationChanged,
                      isLoading: _isLoading,
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
