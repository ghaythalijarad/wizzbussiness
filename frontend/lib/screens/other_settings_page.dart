import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_auth_provider.dart';
import '../services/api_service.dart';
import '../services/app_auth_service.dart';
import '../widgets/location_settings_widget.dart';
import '../models/business.dart';
import '../screens/signin_screen.dart';
import '../theme/cravevolt_theme.dart';

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
        backgroundColor: CraveVoltColors.surface,
        title: Text(
          'Authentication Required',
          style: TextStyle(color: CraveVoltColors.textPrimary),
        ),
        content: Text(
          'Please sign in to access location settings.',
          style: TextStyle(color: CraveVoltColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context, rootNavigator: true).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const SignInScreen(
                    noticeMessage:
                        'Please sign in to access location settings.',
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: CraveVoltColors.neonLime,
              foregroundColor: CraveVoltColors.background,
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
          backgroundColor: CraveVoltColors.neonLime,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.failedToSaveLocation}: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: CraveVoltColors.background,
        appBar: AppBar(
          title: Text(loc.businessLocation),
          backgroundColor: CraveVoltColors.surface,
          foregroundColor: CraveVoltColors.textPrimary,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: CraveVoltColors.surface,
            statusBarIconBrightness: Brightness.light,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: CraveVoltColors.textPrimary,
              shape: const RoundedRectangleBorder(),
              elevation: 0,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: CraveVoltColors.neonLime,
            backgroundColor: CraveVoltColors.background,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: CraveVoltColors.background,
      appBar: AppBar(
        title: Text(loc.businessLocation),
        backgroundColor: CraveVoltColors.surface,
        foregroundColor: CraveVoltColors.textPrimary,
        elevation: 2,
        shadowColor: CraveVoltColors.neonLime.withOpacity(0.1),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: CraveVoltColors.surface,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: CraveVoltColors.textPrimary,
            shape: const RoundedRectangleBorder(),
            elevation: 0,
            padding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AppAuthService.signOut();
              Navigator.of(context, rootNavigator: true).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const SignInScreen(
                    noticeMessage:
                        'You have been signed out. Please sign in again.',
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
                color: CraveVoltColors.neonLime,
                backgroundColor: CraveVoltColors.background,
              ),
            )
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
                          color: CraveVoltColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadBusinessLocationSettings,
                        icon: const Icon(Icons.refresh),
                        label: Text(loc.retry),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CraveVoltColors.neonLime,
                          foregroundColor: CraveVoltColors.background,
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
                        color: CraveVoltColors.surface,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: CraveVoltColors.neonLime.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: CraveVoltColors.neonLime
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: CraveVoltColors.neonLime
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.location_on,
                                      color: CraveVoltColors.neonLime,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    loc.businessLocation,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: CraveVoltColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                loc.businessLocationDescription,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: CraveVoltColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Location Information Section
                      Card(
                        color: CraveVoltColors.surface,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: CraveVoltColors.neonLime.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: CraveVoltColors.neonLime
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: CraveVoltColors.neonLime
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: CraveVoltColors.neonLime,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    loc.locationInformation,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: CraveVoltColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
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
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: CraveVoltColors.neonLime.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 16,
            color: CraveVoltColors.neonLime,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CraveVoltColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: CraveVoltColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
