import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../models/business.dart';
import '../l10n/app_localizations.dart';
import '../services/app_auth_service.dart';
import '../services/api_service.dart';
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
      // First try to get detailed business data from API
      final apiService = ApiService();
      List<Map<String, dynamic>>? businesses;
      
      try {
        businesses = await apiService.getUserBusinesses();
        print('🏢 Account Settings: Fetched ${businesses.length} businesses from API');
      } catch (e) {
        print('⚠️ Account Settings: Could not fetch businesses from API: $e');
      }

      // Use AppAuthService to get current user
      final currentUser = await AppAuthService.getCurrentUser();
      if (currentUser != null) {
        // Try to find matching business data
        Map<String, dynamic>? businessData;
        if (businesses != null && businesses.isNotEmpty) {
          businessData = businesses.firstWhere(
            (business) => business['businessId'] == widget.business.id ||
                         business['business_id'] == widget.business.id ||
                         business['id'] == widget.business.id,
            orElse: () => businesses!.first,
          );
          print('📋 Account Settings: Using business data: ${businessData['business_name']} with owner: ${businessData['owner_name']}');
        }

        setState(() {
          _userData = {
            'business_name': businessData?['business_name'] ?? widget.business.name,
            'owner_name': businessData?['owner_name'] ?? 
                          widget.business.ownerName ?? 
                          currentUser['name'] ?? 
                          currentUser['given_name'] ?? 
                          '${currentUser['given_name'] ?? ''} ${currentUser['family_name'] ?? ''}'.trim() ?? 
                          '',
            'email': currentUser['email'] ?? '',
            'phone_number': businessData?['phone_number'] ?? 
                           currentUser['phone_number'] ?? 
                           widget.business.phone ?? '',
            'business_type': businessData?['business_type'] ?? 
                            widget.business.businessType.toString().split('.').last,
            'address': {
              'home_address': '',
              'street': businessData?['address'] ?? widget.business.address ?? '',
              'neighborhood': '',
              'district': businessData?['district'] ?? '',
              'city': businessData?['city'] ?? '',
              'country': businessData?['country'] ?? '',
            },
            'created_at': businessData?['created_at'],
          };
          _isLoadingUserData = false;

          // Update controllers with real user data
          _businessNameController.text = _userData?['business_name'] ?? '';
          _ownerNameController.text = _userData?['owner_name'] ?? '';
          _addressController.text = _formatAddress(_userData?['address']);
          
          print('✅ Account Settings: Owner name set to: ${_userData?['owner_name']}');
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
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00D4FF),
                Color(0xFF3399FF),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF3399FF),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                l10n.accountSettings,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF00D4FF),
                      Color(0xFF3399FF),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // User icon
                    const Positioned(
                      bottom: 30,
                      left: 20,
                      child: Icon(
                        Icons.account_circle_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadUserData,
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: _saveChanges,
                tooltip: 'Edit Profile',
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: _isLoadingUserData
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState(l10n, theme)
                    : _buildAccountContent(l10n, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3399FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF3399FF),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading your account information...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.errorLoadingUserData,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadUserData,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3399FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountContent(AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Overview Card
          _buildAccountOverviewCard(l10n, theme),
          
          const SizedBox(height: 24),
          
          // Personal Information Section
          _buildSectionHeader('Personal Information', Icons.person_rounded),
          const SizedBox(height: 16),
          _buildPersonalInfoCard(l10n, theme),
          
          const SizedBox(height: 32),
          
          // Business Information Section
          _buildSectionHeader('Business Information', Icons.business_rounded),
          const SizedBox(height: 16),
          _buildBusinessInfoCard(l10n, theme),
          
          const SizedBox(height: 32),
          
          // Account Status Section
          _buildSectionHeader('Account Status', Icons.verified_user_rounded),
          const SizedBox(height: 16),
          _buildAccountStatusCard(l10n, theme),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3399FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF3399FF),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountOverviewCard(AppLocalizations l10n, ThemeData theme) {
    final businessName = _userData?['business_name'] ?? 'Business';
    final ownerName = _userData?['owner_name'] ?? 'Owner';
    final email = _userData?['email'] ?? '';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3399FF),
            Color(0xFF00C1E8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3399FF).withOpacity(0.3),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_circle_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      businessName,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.email_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildModernInfoTile(
            l10n.ownerName,
            _userData?['owner_name'] ?? 'Not provided',
            Icons.person_rounded,
            const Color(0xFF3399FF),
          ),
          const Divider(height: 32),
          _buildModernInfoTile(
            l10n.emailAddress,
            _userData?['email'] ?? 'Not provided',
            Icons.email_rounded,
            const Color(0xFF00C1E8),
            isLtr: true,
          ),
          const Divider(height: 32),
          _buildModernInfoTile(
            l10n.phoneNumber,
            _userData?['phone_number'] ?? 'Not provided',
            Icons.phone_rounded,
            const Color(0xFF00D4FF),
            isLtr: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoCard(AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildModernInfoTile(
            l10n.businessName,
            _userData?['business_name'] ?? 'Not provided',
            Icons.business_rounded,
            const Color(0xFF3399FF),
          ),
          const Divider(height: 32),
          _buildModernInfoTile(
            l10n.businessType,
            _userData?['business_type'] ?? 'Not specified',
            Icons.category_rounded,
            const Color(0xFF00C1E8),
          ),
          const Divider(height: 32),
          _buildModernInfoTile(
            l10n.businessAddressLabel,
            _formatAddress(_userData?['address']) ?? 'Not provided',
            Icons.location_on_rounded,
            const Color(0xFF00D4FF),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStatusCard(AppLocalizations l10n, ThemeData theme) {
    final createdAt = _userData?['created_at'];
    final registrationDate = _formatDate(createdAt);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatusChip(
                  'Active',
                  true,
                  Colors.green,
                  Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusChip(
                  'Verified',
                  true,
                  const Color(0xFF3399FF),
                  Icons.verified_rounded,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildModernInfoTile(
            l10n.registrationDate,
            registrationDate.isNotEmpty ? registrationDate : 'Not available',
            Icons.calendar_today_rounded,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoTile(
    String label,
    String value,
    IconData icon,
    Color iconColor, {
    bool isLtr = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textDirection: isLtr ? ui.TextDirection.ltr : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, bool isActive, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? color : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
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
