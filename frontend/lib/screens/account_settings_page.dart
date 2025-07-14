import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../models/business.dart';
import '../l10n/app_localizations.dart';
import '../services/app_auth_service.dart';
import '../screens/login_page.dart';

class AccountSettingsPage extends StatefulWidget {
  final Business business;

  const AccountSettingsPage({Key? key, required this.business})
      : super(key: key);

  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late TextEditingController _businessNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _addressController;

  Map<String, dynamic>? _userData;
  bool _isLoadingUserData = true;
  String? _errorMessage;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty text - will be populated after loading user data
    _businessNameController = TextEditingController();
    _ownerNameController = TextEditingController();
    _addressController = TextEditingController();

    _validateAuthenticationAndInitialize();
  }

  Future<void> _validateAuthenticationAndInitialize() async {
    try {
      // Check if business ID is provided
      if (widget.business.id.isEmpty) {
        _showAuthenticationRequiredDialog();
        return;
      }

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

      // Load user data after authentication is verified
      _loadUserData();
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
        content: Text(
          'Please sign in to access account settings',
          style: TextStyle(
            color: const Color(0xFF001133).withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => _navigateToLogin(),
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

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => LoginPage(
          onLanguageChanged: (locale) {
            // Handle language change if needed
          },
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUserData = true;
      _errorMessage = null;
    });

    try {
      // Use AppAuthService to get current user
      final currentUser = await AppAuthService.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _userData = {
            'business_name': widget.business.name,
            'owner_name': currentUser['name'] ?? '',
            'email': currentUser['email'] ?? '',
            'phone_number': currentUser['phone_number'] ?? '',
            'address': {
              'home_address': '',
              'street': widget.business.address,
              'neighborhood': '',
              'district': '',
              'city': '',
              'country': '',
            }
          };
          _isLoadingUserData = false;

          // Update controllers with real user data
          _businessNameController.text = _userData?['business_name'] ?? '';
          _ownerNameController.text = _userData?['owner_name'] ?? '';
          _addressController.text = _formatAddress(_userData?['address']);
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load user data - user not authenticated';
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user data: $e';
        _isLoadingUserData = false;
      });
    }
  }

  String _formatAddress(Map<String, dynamic>? address) {
    if (address == null) {
      return '';
    }
    // Construct a formatted address string from the address map
    return '${address['home_address'] ?? ''}, ${address['street'] ?? ''}, ${address['neighborhood'] ?? ''}, ${address['district'] ?? ''}, ${address['city'] ?? ''}, ${address['country'] ?? ''}';
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    // TODO: Implement save logic
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00C1E8),
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    ;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountSettings),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: _isLoadingUserData
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.errorLoadingUserData,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    child: ListView(
                      children: [
                        _buildInfoTile(
                            l10n.ownerName, _userData?['owner_name'] ?? ''),
                        _buildInfoTile(
                            l10n.emailAddress, _userData?['email'] ?? ''),
                        _buildInfoTile(
                            l10n.phoneNumber, _userData?['phone_number'] ?? '',
                            isLtr: true),
                        _buildInfoTile(l10n.businessAddressLabel,
                            _formatAddress(_userData?['address'])),
                        _buildInfoTile(l10n.businessType,
                            _userData?['business_type'] ?? ''),
                        _buildInfoTile(l10n.registrationDate,
                            _formatDate(_userData?['created_at'])),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoTile(String title, String subtitle, {bool isLtr = false}) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        textDirection: isLtr ? ui.TextDirection.ltr : null,
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) {
      return '';
    }
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat.yMMMd().format(dateTime);
    } catch (e) {
      return dateString;
    }
  }
}
