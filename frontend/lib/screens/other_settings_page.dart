import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_auth_provider.dart';
import '../services/api_service.dart';
import '../services/app_auth_service.dart';
import '../widgets/location_settings_widget.dart';
import '../models/business.dart';
import '../screens/login_page.dart';

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
    print('🔐 Starting validation for OtherSettingsPage...');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final appAuthProvider =
          Provider.of<AppAuthProvider>(context, listen: false);

      try {
        print('🤔 Checking authentication status...');
        final isValid = await appAuthProvider.validateAuthentication();
        print('✅ Authentication status valid: $isValid');

        if (isValid) {
          if (mounted) {
            print(
                '🚀 Authentication successful, proceeding to load settings...');
            setState(() {
              _isInitializing = false;
            });
            await _loadBusinessLocationSettings();
          }
        } else {
          print('🚨 Authentication failed, showing dialog.');
          _showAuthenticationRequiredDialog();
        }
      } catch (e) {
        print('❌ Authentication validation failed with error: $e');
        _showAuthenticationRequiredDialog();
      }
    });
  }

  void _showAuthenticationRequiredDialog() {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Authentication Required'),
        content: Text('Please sign in to access location settings.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context, rootNavigator: true).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => LoginPage(
                    onLanguageChanged: (Locale) {}, // Dummy function
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
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
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _isLoadingSettings = true;
      _errorMessage = null;
    });
    try {
      if (widget.business != null) {
        // Load settings from passed Business object
        setState(() {
          _latitude = widget.business!.latitude;
          _longitude = widget.business!.longitude;
          _address = widget.business!.address;
          _isLoadingSettings = false;
        });
        print('✅ Location settings loaded from Business object');
      } else {
        // Fall back to retrieving via getUserBusinesses
        final apiService = ApiService();
        final businesses = await apiService.getUserBusinesses();
        if (businesses.isNotEmpty) {
          final businessData = businesses.first;
          setState(() {
            _latitude = businessData['latitude'] as double?;
            _longitude = businessData['longitude'] as double?;
            _address = businessData['address'] as String?;
            _isLoadingSettings = false;
          });
          print('✅ Location settings loaded via getUserBusinesses fallback');
        } else {
          setState(() {
            _errorMessage = loc.noBusinessFoundForUser;
            _isLoadingSettings = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading location settings: $e');
      setState(() {
        _errorMessage = '${loc.failedToSaveLocation}: $e';
        _isLoadingSettings = false;
      });
    }
  }

  Future<void> _saveBusinessLocation(
      double? latitude, double? longitude, String? address) async {
    final loc = AppLocalizations.of(context)!;
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
          throw Exception(loc.noBusinessFoundForUser);
        }
        businessId = businesses.first['businessId'] ??
            businesses.first['id'] ??
            businesses.first['business_id'];
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
      await apiService.updateBusinessLocationSettings(
          businessId, locationSettings);
      setState(() {
        _latitude = latitude;
        _longitude = longitude;
        _address = address;
        _isLoading = false;
      });
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
          content: Text('${loc.failedToSaveLocation}: $e'),
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
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(),
                elevation: 0,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.businessLocation),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(),
              elevation: 0,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AppAuthService.signOut();
              Navigator.of(context, rootNavigator: true).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => LoginPage(
                    onLanguageChanged: (Locale) {}, // Dummy function
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoadingSettings
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadBusinessLocationSettings,
                        icon: const Icon(Icons.refresh),
                        label: Text(loc.retry),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description Section
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 20),
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
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                loc.businessLocationDescription,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Location Information Section
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    loc.locationInformation,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInfoItem(
                                Icons.visibility,
                                loc.customerVisibility,
                                loc.customerVisibilityDescription,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoItem(
                                Icons.delivery_dining,
                                loc.deliveryOptimization,
                                loc.deliveryOptimizationDescription,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoItem(
                                Icons.security,
                                loc.privacyAndSecurity,
                                loc.privacyAndSecurityDescription,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Location Settings Widget
                      LocationSettingsWidget(
                        initialLatitude: _latitude,
                        initialLongitude: _longitude,
                        initialAddress: _address,
                        onLocationChanged: _saveBusinessLocation,
                        isLoading: _isLoading,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
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
