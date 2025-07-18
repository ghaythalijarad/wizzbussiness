import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/app_auth_service.dart';
import '../widgets/location_settings_widget.dart';
import '../models/business.dart';

class OtherSettingsPage extends StatefulWidget {
  final Business? business;

  const OtherSettingsPage({Key? key, this.business}) : super(key: key);

  @override
  _OtherSettingsPageState createState() => _OtherSettingsPageState();
}

class _OtherSettingsPageState extends State<OtherSettingsPage> {
  double? _latitude;
  double? _longitude;
  String? _address;
  bool _isLoading = false;
  bool _isLoadingSettings = true;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _validateAuthenticationAndInitialize();
  }

  Future<void> _validateAuthenticationAndInitialize() async {
    try {
      // Check if user is signed in
      final isSignedIn = await AppAuthService.isSignedIn();
      if (!isSignedIn) {
        _showAuthenticationRequiredDialog();
        return;
      }

      // Verify current user and access token
      final currentUser = await AppAuthService.getCurrentUser();
      final accessToken = await AppAuthService.getAccessToken();

      if (currentUser == null || accessToken == null) {
        _showAuthenticationRequiredDialog();
        return;
      }

      // If all checks pass, proceed with initialization
      setState(() {
        _isInitializing = false;
      });

      // Load business location settings
      _loadBusinessLocationSettings();
    } catch (e) {
      print('Authentication validation failed: $e');
      _showAuthenticationRequiredDialog();
    }
  }

  void _showAuthenticationRequiredDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(
          Icons.security,
          color: Color(0xFF00C1E8),
          size: 48,
        ),
        title: Text(
          loc.userNotLoggedIn,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF001133),
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Please sign in to access location settings',
          style: TextStyle(
            color: Color(0xFF001133),
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF00C1E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(loc.signIn),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  Future<void> _loadBusinessLocationSettings() async {
    print('🗺️ Loading business location settings...');
    setState(() {
      _isLoadingSettings = true;
      _errorMessage = null;
    });

    try {
      if (widget.business != null) {
        print('📊 Business object available: ${widget.business!.name}');
        print('📍 Current latitude: ${widget.business!.latitude}');
        print('📍 Current longitude: ${widget.business!.longitude}');
        print('🏠 Current address: ${widget.business!.address}');
        
        // Load from existing business data
        setState(() {
          _latitude = widget.business!.latitude;
          _longitude = widget.business!.longitude;
          _address = widget.business!.address;
          _isLoadingSettings = false;
        });
        
        print('✅ Location settings loaded from business object');
      } else {
        print('❌ No business object provided, loading from API...');
        // Load from API
        final apiService = ApiService();
        final businesses = await apiService.getUserBusinesses();
        
        if (businesses.isNotEmpty) {
          final businessData = businesses.first;
          setState(() {
            _latitude = (businessData['latitude'] as num?)?.toDouble();
            _longitude = (businessData['longitude'] as num?)?.toDouble();
            _address = businessData['address'] as String?;
            _isLoadingSettings = false;
          });
        } else {
          setState(() {
            _errorMessage = 'No business found for user';
            _isLoadingSettings = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading location settings: $e');
      setState(() {
        _errorMessage = 'Failed to load business settings: $e';
        _isLoadingSettings = false;
      });
    }
  }

  Future<void> _saveBusinessLocation(double? latitude, double? longitude, String? address) async {
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      
      // Get business ID
      String businessId;
      if (widget.business != null) {
        businessId = widget.business!.id;
      } else {
        final businesses = await apiService.getUserBusinesses();
        if (businesses.isEmpty) {
          throw Exception('No business found for user');
        }
        businessId = businesses.first['businessId'] ?? businesses.first['id'] ?? businesses.first['business_id'];
      }

      // Prepare location settings
      final locationSettings = {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Save to business settings table via existing POS settings endpoint 
      // (we'll reuse the infrastructure for business settings)
      await apiService.updateBusinessLocationSettings(businessId, locationSettings);

      setState(() {
        _latitude = latitude;
        _longitude = longitude;
        _address = address;
        _isLoading = false;
      });

      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.locationSaved),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.businessLocation),
          backgroundColor: const Color(0xFF00C1E8),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.businessLocation),
        backgroundColor: const Color(0xFF00C1E8),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingSettings
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBusinessLocationSettings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header section
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Theme.of(context).primaryColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    loc.businessLocation,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Set your business location to help customers find you and improve delivery accuracy.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Location settings widget
                      LocationSettingsWidget(
                        initialLatitude: _latitude,
                        initialLongitude: _longitude,
                        initialAddress: _address,
                        onLocationChanged: _saveBusinessLocation,
                        isLoading: _isLoading,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Additional information card
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Location Information',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInfoItem(
                                Icons.visibility,
                                'Customer Visibility',
                                'Your location will be shown to customers when they place orders',
                              ),
                              const SizedBox(height: 8),
                              _buildInfoItem(
                                Icons.delivery_dining,
                                'Delivery Optimization',
                                'Accurate location helps optimize delivery routes and timing',
                              ),
                              const SizedBox(height: 8),
                              _buildInfoItem(
                                Icons.security,
                                'Privacy & Security',
                                'Your location data is encrypted and securely stored',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
