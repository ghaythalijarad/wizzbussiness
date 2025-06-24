import 'package:flutter/material.dart';
import './account_settings_page.dart';
import './pos_settings_page.dart';
import '../l10n/app_localizations.dart';
import '../models/business.dart';
import '../models/order.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../screens/login_page.dart';

class ProfileSettingsPage extends StatefulWidget {
  final Business business;
  final Function(Locale)? onLanguageChanged;
  final List<Order> orders;
  final Function(int)? onNavigateToPage;
  final Function(String, OrderStatus)? onOrderUpdated;

  const ProfileSettingsPage({
    Key? key,
    required this.business,
    this.onLanguageChanged,
    required this.orders,
    this.onNavigateToPage,
    this.onOrderUpdated,
  }) : super(key: key);

  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final AppState _appState = AppState();
  Map<String, dynamic>? _userData;
  bool _isLoadingUserData = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
    _loadUserData();
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUserData = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.getCurrentUser();
      if (response['success'] == true) {
        setState(() {
          _userData = response['user'];
          _isLoadingUserData = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load user data';
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

  String _getBusinessTypeDisplayName(String? businessType) {
    if (businessType == null) return 'Not specified';
    
    switch (businessType.toLowerCase()) {
      case 'restaurant':
        return 'Restaurant';
      case 'store':
        return 'Store';
      case 'kitchen':
        return 'Kitchen';
      case 'pharmacy':
        return 'Pharmacy';
      default:
        return businessType;
    }
  }

  String _formatPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return 'Not provided';
    }
    
    // If it doesn't start with +964, add it
    if (!phoneNumber.startsWith('+964')) {
      return '+964 $phoneNumber';
    }
    
    return phoneNumber;
  }

  Widget _buildUserProfileHeader() {
    if (_isLoadingUserData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00D4FF),
              Color(0xFF0099CC),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF5722),
              Color(0xFFE64A19),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading profile',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF5722),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00D4FF),
            Color(0xFF0099CC),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userData?['business_name'] ?? 'Business Name',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getBusinessTypeDisplayName(_userData?['business_type']),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatusChip(
                'Active',
                _userData?['is_active'] ?? false,
                _userData?['is_active'] == true ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildStatusChip(
                'Verified',
                _userData?['is_verified'] ?? false,
                _userData?['is_verified'] == true ? Colors.blue : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isActive, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoCards() {
    if (_userData == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildInfoCard(
          'Email Address',
          _userData?['email'] ?? 'Not provided',
          Icons.email,
          const Color(0xFF2196F3),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          'Phone Number',
          _formatPhoneNumber(_userData?['phone_number']),
          Icons.phone,
          const Color(0xFFFF9800),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.logout();
      _appState.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => LoginPage(
                onLanguageChanged: widget.onLanguageChanged ?? (locale) {})),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Profile Settings',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (_isLoadingUserData)
              SizedBox(
                height: 12,
                width: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              )
            else if (_userData != null && _userData!['business_name'] != null)
              Text(
                _userData!['business_name'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00D4FF),
                Color(0xFF0099CC),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8FBFF), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  // User Profile Header
                  _buildUserProfileHeader(),
                  const SizedBox(height: 24),
                  
                  // Quick Info Cards
                  _buildQuickInfoCards(),
                  const SizedBox(height: 24),
                  
                  // Settings Cards
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.account_circle),
                      title: Text(loc.accountSettings),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AccountSettingsPage(business: widget.business),
                          ),
                        );
                      },
                    ),
                  ),
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.point_of_sale),
                      title: Text(loc.posSettings),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PosSettingsPage(business: widget.business),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to Language Settings Page
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(loc.languageSettings),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _signOut,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(loc.logout),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
