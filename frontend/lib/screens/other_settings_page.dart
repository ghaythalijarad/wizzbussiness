import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/location_settings_widget.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/design_system/typography_system.dart';

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
          SnackBar(
            content: Text('Location settings saved successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save location settings: $e'),
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
      backgroundColor: AppColors.backgroundVariant,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.secondary.withOpacity(0.03),
              AppColors.background,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern App Bar
              _buildModernAppBar(loc),
              
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(GoldenRatio.spacing20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Section
                              _buildHeaderSection(loc),
                              SizedBox(height: GoldenRatio.spacing24),
                              
                              // Business Address Section
                              _buildAddressSection(loc),
                              SizedBox(height: GoldenRatio.spacing24),

                              // GPS Location Section
                              _buildGPSSection(),
                              SizedBox(height: GoldenRatio.spacing24),

                              // Save Button
                              _buildSaveButton(loc),
                              
                              // Bottom spacing
                              SizedBox(height: GoldenRatio.spacing24),
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

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(GoldenRatio.spacing24 + GoldenRatio.spacing8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.1),
              blurRadius: GoldenRatio.spacing20,
              offset: Offset(0, GoldenRatio.spacing8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            SizedBox(height: GoldenRatio.spacing16),
            Text(
              'Loading location settings...',
              style: TypographySystem.bodyLarge.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: GoldenRatio.spacing20,
        vertical: GoldenRatio.spacing16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.04),
            blurRadius: GoldenRatio.spacing12,
            offset: Offset(0, GoldenRatio.spacing4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SizedBox(width: GoldenRatio.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.locationSettings,
                  style: TypographySystem.headlineSmall.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage your business location and GPS coordinates',
                  style: TypographySystem.bodyMedium.copyWith(
                    color: AppColors.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: GoldenRatio.spacing8,
                  offset: Offset(0, GoldenRatio.spacing4),
                ),
              ],
            ),
            child: IconButton(
              icon: _isLoading
                  ? SizedBox(
                      width: GoldenRatio.spacing20,
                      height: GoldenRatio.spacing20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Icon(Icons.save_rounded, color: AppColors.onPrimary),
              onPressed: _isLoading ? null : _saveLocationSettings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.all(GoldenRatio.spacing24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.primary.withOpacity(0.02),
            AppColors.secondary.withOpacity(0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.06),
            blurRadius: GoldenRatio.spacing24,
            offset: Offset(0, GoldenRatio.spacing8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(GoldenRatio.spacing16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: GoldenRatio.spacing24 + GoldenRatio.spacing8,
                ),
              ),
              SizedBox(width: GoldenRatio.spacing20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business Location',
                      style: TypographySystem.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    SizedBox(height: GoldenRatio.spacing8),
                    Text(
                      'Set your business location to help customers find you and improve delivery accuracy.',
                      style: TypographySystem.bodyLarge.copyWith(
                        color: AppColors.onSurface.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: GoldenRatio.spacing20),
          // Feature highlights
          Row(
            children: [
              Expanded(
                child: _buildFeatureHighlight(
                  icon: Icons.visibility_rounded,
                  title: 'Customer Visibility',
                  description:
                      'Your location will be shown to customers when they place orders',
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: GoldenRatio.spacing16),
              Expanded(
                child: _buildFeatureHighlight(
                  icon: Icons.route_rounded,
                  title: 'Delivery Optimization',
                  description:
                      'Accurate location helps optimize delivery routes and timing',
                  color: AppColors.secondary,
                ),
              ),
              SizedBox(width: GoldenRatio.spacing16),
              Expanded(
                child: _buildFeatureHighlight(
                  icon: Icons.security_rounded,
                  title: 'Privacy & Security',
                  description:
                      'Your location data is encrypted and securely stored',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHighlight({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(GoldenRatio.spacing16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(GoldenRatio.spacing8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
            ),
            child: Icon(
              icon,
              color: color,
              size: GoldenRatio.spacing20,
            ),
          ),
          SizedBox(height: GoldenRatio.spacing12),
          Text(
            title,
            style: TypographySystem.titleSmall.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: GoldenRatio.spacing8),
          Text(
            description,
            style: TypographySystem.bodySmall.copyWith(
              color: AppColors.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.all(GoldenRatio.spacing24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: GoldenRatio.spacing20,
            offset: Offset(0, GoldenRatio.sm),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(GoldenRatio.spacing12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                ),
                child: Icon(
                  Icons.business,
                  color: AppColors.onPrimaryContainer,
                  size: GoldenRatio.spacing24,
                ),
              ),
              SizedBox(width: GoldenRatio.spacing16),
              Text(
                'Business Address',
                style: TypographySystem.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: GoldenRatio.spacing24),

          // Address form fields in Material 3 style
          Row(
            children: [
              Expanded(
                child: _buildModernTextField(
                  controller: _cityController,
                  label: 'City',
                  icon: Icons.location_city,
                  color: AppColors.primary,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'City required';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: GoldenRatio.spacing16),
              Expanded(
                child: _buildModernTextField(
                  controller: _districtController,
                  label: 'District',
                  icon: Icons.map,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          SizedBox(height: GoldenRatio.spacing20),

          _buildModernTextField(
            controller: _countryController,
            label: 'Country',
            icon: Icons.public,
            color: AppColors.primary,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter country';
              }
              return null;
            },
          ),
          SizedBox(height: GoldenRatio.spacing20),

          _buildModernTextField(
            controller: _streetController,
            label: 'Street Name',
            icon: Icons.streetview,
            color: AppColors.secondary,
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
      style: TypographySystem.bodyLarge.copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Container(
          margin: EdgeInsets.all(GoldenRatio.sm),
          padding: EdgeInsets.all(GoldenRatio.sm),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
          ),
          child: Icon(
            icon,
            color: color,
            size: GoldenRatio.spacing24,
          ),
        ),
        filled: true,
        fillColor: color.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
          borderSide: BorderSide(color: color.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
          borderSide: BorderSide(color: color.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
          borderSide: BorderSide(color: color, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: TypographySystem.bodyMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: TypographySystem.bodySmall.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: GoldenRatio.spacing20,
          vertical: GoldenRatio.spacing16,
        ),
      ),
    );
  }

  Widget _buildGPSSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: GoldenRatio.spacing20,
            offset: Offset(0, GoldenRatio.sm),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(GoldenRatio.spacing24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryContainer.withOpacity(0.3),
                  AppColors.secondaryContainer.withOpacity(0.1),
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
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                  ),
                  child: Icon(
                    Icons.gps_fixed,
                    color: AppColors.onPrimaryContainer,
                    size: GoldenRatio.spacing24,
                  ),
                ),
                SizedBox(width: GoldenRatio.spacing16),
                Expanded(
                  child: Text(
                    'GPS Location',
                    style: TypographySystem.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(GoldenRatio.spacing24),
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
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: GoldenRatio.spacing20,
            offset: Offset(0, GoldenRatio.sm),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveLocationSettings,
          borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: GoldenRatio.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading) ...[
                  SizedBox(
                    width: GoldenRatio.spacing20,
                    height: GoldenRatio.spacing20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                    ),
                  ),
                  SizedBox(width: GoldenRatio.spacing12),
                ] else ...[
                  Container(
                    padding: EdgeInsets.all(GoldenRatio.xs),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(GoldenRatio.sm),
                    ),
                    child: Icon(
                      Icons.save,
                      color: AppColors.onSecondary,
                      size: GoldenRatio.lg,
                    ),
                  ),
                  SizedBox(width: GoldenRatio.spacing12),
                ],
                Text(
                  _isLoading ? 'Saving...' : 'Save Location Settings',
                  style: TypographySystem.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onPrimary,
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
