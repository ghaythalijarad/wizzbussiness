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

      debugPrint('🔍 DEBUGGING BUSINESS OBJECT DATA:');
      debugPrint('  Business ID: ${business.id}');
      debugPrint('  Business Name: ${business.name}');
      debugPrint('  Raw Business City: "${business.city}"');
      debugPrint('  Raw Business District: "${business.district}"');
      debugPrint('  Raw Business Street: "${business.street}"');
      debugPrint('  Raw Business Country: "${business.country}"');
      debugPrint('  Raw Business Address: "${business.address}"');
      debugPrint('  Business Latitude: ${business.latitude}');
      debugPrint('  Business Longitude: ${business.longitude}');

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

      debugPrint('🎯 FORM FIELD VALUES AFTER BUSINESS MODEL EXTRACTION:');
      debugPrint('  City Controller: "${_cityController.text}"');
      debugPrint('  District Controller: "${_districtController.text}"');
      debugPrint('  Street Controller: "${_streetController.text}"');
      debugPrint('  Country Controller: "${_countryController.text}"');
      debugPrint('  Address Variable: "$_address"');
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
      debugPrint('❌ Error in _loadLocationSettings: $e');
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF32CD32).withOpacity(0.05), // Lime Green
              const Color(0xFFFFD300).withOpacity(0.03), // Gold
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Material 3 App Bar
              _buildModernAppBar(context, loc),

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Section
                              _buildHeaderSection(loc),
                              const SizedBox(height: 32),
                              
                              // Business Address Section
                              _buildAddressSection(loc, colorScheme),
                              const SizedBox(height: 24),

                              // GPS Location Section
                              _buildGPSSection(colorScheme),
                              const SizedBox(height: 32),

                              // Save Button
                              _buildSaveButton(loc),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF32CD32), // Lime Green
            const Color(0xFF228B22), // Darker Lime Green
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF32CD32).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.locationSettings,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure your business location',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD300), // Gold
                  const Color(0xFFC7A600), // Darker Gold
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD300).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.save, color: Colors.black87),
              onPressed: _isLoading ? null : _saveLocationSettings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF32CD32).withOpacity(0.1),
                  const Color(0xFFFFD300).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: CircularProgressIndicator(
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF32CD32)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading location settings...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFF32CD32).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF32CD32).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF32CD32), Color(0xFF228B22)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Location',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set your business location to help customers find you and improve delivery accuracy.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(AppLocalizations loc, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFD300).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD300), Color(0xFFC7A600)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Business Address',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Address form fields in Material 3 style
          Row(
            children: [
              Expanded(
                child: _buildModernTextField(
                  controller: _cityController,
                  label: 'City',
                  icon: Icons.location_city,
                  color: const Color(0xFF32CD32),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'City required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernTextField(
                  controller: _districtController,
                  label: 'District',
                  icon: Icons.map,
                  color: const Color(0xFFFFD300),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildModernTextField(
            controller: _countryController,
            label: 'Country',
            icon: Icons.public,
            color: const Color(0xFF32CD32),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter country';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          _buildModernTextField(
            controller: _streetController,
            label: 'Street Name',
            icon: Icons.streetview,
            color: const Color(0xFFFFD300),
            helperText: 'Street name used for location mapping and delivery',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Street name is required for mapping';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1C1C1C),
      ),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        filled: true,
        fillColor: color.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        labelStyle: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildGPSSection(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF32CD32).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF32CD32).withOpacity(0.1),
                  const Color(0xFFFFD300).withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF32CD32), Color(0xFF228B22)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.gps_fixed,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'GPS Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: LocationSettingsWidget(
              initialLatitude: _latitude,
              initialLongitude: _longitude,
              initialAddress: _address,
              onLocationChanged: _onLocationChanged,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations loc) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF32CD32), // Lime Green
            const Color(0xFF228B22), // Darker Lime Green
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF32CD32).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveLocationSettings,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD300), // Gold accent
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.save,
                      color: Colors.black87,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  _isLoading ? 'Saving...' : 'Save Location Settings',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
