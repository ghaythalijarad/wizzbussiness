import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../l10n/app_localizations.dart';
import '../providers/session_provider.dart';
import '../providers/business_provider.dart';
import '../screens/signin_screen.dart';

class AccountSettingsPage extends ConsumerStatefulWidget {
  final Business business;

  const AccountSettingsPage({Key? key, required this.business})
      : super(key: key);

  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends ConsumerState<AccountSettingsPage> {
  late TextEditingController _businessNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _addressController;

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
    final session = ref.read(sessionProvider);
    if (!session.isAuthenticated) {
      // Re-check in case tokens were restored later
      await ref.read(sessionProvider.notifier).checkAuthStatus();
      final refreshed = ref.read(sessionProvider);
      if (!refreshed.isAuthenticated) {
        _showAuthenticationRequiredDialog();
        return;
      }
    }

    // If all checks pass, proceed with initialization
    setState(() {
      _isInitializing = false;
    });

    // Load user data after authentication is verified
    _loadUserData();
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
            color: const Color(0xFF001133).withAlpha(179),
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
        builder: (context) => const SignInScreen(
          noticeMessage: 'Please sign in to access account settings',
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _loadUserData() async {
    // This method is now simplified since we use ref.watch(businessProvider) in build()
    // Just ensure the session is valid
    final session = ref.read(sessionProvider);
    if (!session.isAuthenticated) {
      _showAuthenticationRequiredDialog();
    }
  }

  String _formatAddress(dynamic address) {
    if (address == null) return '';
    // Plain string address
    if (address is String) return address;
    // DynamoDB atomic string
    if (address is Map<String, dynamic> && address.containsKey('S')) {
      return address['S']?.toString() ?? '';
    }
    // DynamoDB attribute map wrapper
    if (address is Map<String, dynamic> && address.containsKey('M')) {
      return _formatAddress(address['M']);
    }
    // Now address should be a map of components
    final Map<String, dynamic> addrMap = Map<String, dynamic>.from(address as Map);
    String extract(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is Map<String, dynamic> && v.containsKey('S')) {
        return v['S']?.toString() ?? '';
      }
      if (v is Map<String, dynamic> && v.containsKey('M')) {
        final m = Map<String, dynamic>.from(v['M'] as Map);
        if (m.containsKey('S')) return m['S']?.toString() ?? '';
        // Fallback: join nested values
        return m.values.map((e) => extract(e)).where((s) => s.isNotEmpty).join(' ');
      }
      return v.toString();
    }
    final components = <String>[
      extract(addrMap['home_address']),
      extract(addrMap['street']),
      extract(addrMap['neighborhood']),
      extract(addrMap['district']),
      extract(addrMap['city']),
      extract(addrMap['country']),
    ].where((c) => c.isNotEmpty).toList();
    return components.join(', ');
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    super.dispose();
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
    final businessAsyncValue = ref.watch(businessProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountSettings),
        backgroundColor: const Color(0xFF00C1E8),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[50],
      body: businessAsyncValue.when(
        loading: () => _buildLoadingState(),
        error: (error, stack) {
          final msg = error.toString();
          // Detect auth-related errors and prompt sign-in
          if (msg.contains('Missing or invalid authorization header') ||
              msg.contains('401') ||
              msg.contains('Invalid or expired access token') ||
              msg.contains('No access token')) {
            // Show dialog and a lightweight placeholder behind it
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showAuthenticationRequiredDialog();
            });
            return _buildErrorStateWithMessage(
                l10n, theme, 'Authentication required.');
          }
          return _buildErrorStateWithMessage(l10n, theme, msg);
        },
        data: (business) {
          if (business == null) {
            return _buildErrorStateWithMessage(l10n, theme, 'No business found for this account');
          }

          // Update controllers with fresh business data
          if (_businessNameController.text != business.name) {
            _businessNameController.text = business.name;
          }
          if (_ownerNameController.text != (business.ownerName ?? '')) {
            _ownerNameController.text = business.ownerName ?? '';
          }
          if (_addressController.text != _formatAddress(business.address)) {
            _addressController.text = _formatAddress(business.address);
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildAccountContentWithBusiness(l10n, theme, business),
                ),
              ),
            ],
          );
        },
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
              color: const Color(0xFF3399FF).withAlpha(25),
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

  Widget _buildErrorStateWithMessage(AppLocalizations l10n, ThemeData theme, String message) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
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
              color: Colors.red.withAlpha(25),
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
            'Error Loading Account',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(businessProvider),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3399FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountContentWithBusiness(AppLocalizations l10n, ThemeData theme, Business business) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account Overview Card with fresh business data
        _buildAccountOverviewCardWithBusiness(l10n, theme, business),

        const SizedBox(height: 24),

        // Personal Information Section
        _buildSectionHeader(l10n.personalInformation, Icons.person_rounded),
        const SizedBox(height: 16),
        _buildPersonalInfoCardWithBusiness(l10n, theme, business),

        const SizedBox(height: 32),

        // Business Information Section
        _buildSectionHeader(l10n.businessInformation, Icons.business_rounded),
        const SizedBox(height: 16),
        _buildBusinessInfoCardWithBusiness(l10n, theme, business),

        const SizedBox(height: 32),

        // Account Status Section
        _buildSectionHeader(l10n.accountStatus, Icons.verified_user_rounded),
        const SizedBox(height: 16),
        _buildAccountStatusCardWithBusiness(l10n, theme, business),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3399FF).withAlpha(25),
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

  Widget _buildAccountOverviewCardWithBusiness(AppLocalizations l10n, ThemeData theme, Business business) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00D4FF),
            Color(0xFF3399FF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3399FF).withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildCircularBusinessPhoto(business.businessPhotoUrl),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        business.businessType.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip(Icons.email, business.email),
              _buildStatChip(Icons.phone, business.phone ?? 'Not provided'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCardWithBusiness(AppLocalizations l10n, ThemeData theme, Business business) {
    return _buildModernCard([
      _buildInfoRow(l10n.ownerName, business.ownerName ?? 'Not provided', Icons.person),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.grey.shade300,
              Colors.transparent,
            ],
          ),
        ),
      ),
      _buildInfoRow(l10n.emailAddress, business.email, Icons.email),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.grey.shade300,
              Colors.transparent,
            ],
          ),
        ),
      ),
      _buildInfoRow(l10n.phoneNumber, business.phone ?? 'Not provided', Icons.phone),
    ]);
  }

  Widget _buildBusinessInfoCardWithBusiness(AppLocalizations l10n, ThemeData theme, Business business) {
    return _buildModernCard([
      _buildInfoRow(l10n.businessName, business.name, Icons.business),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.grey.shade300,
              Colors.transparent,
            ],
          ),
        ),
      ),
      _buildInfoRow(l10n.businessType, business.businessType.name, Icons.category),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.grey.shade300,
              Colors.transparent,
            ],
          ),
        ),
      ),
      _buildInfoRow(l10n.addressLabel, business.address ?? 'Not provided', Icons.location_on, isMultiline: true),
    ]);
  }

  Widget _buildAccountStatusCardWithBusiness(AppLocalizations l10n, ThemeData theme, Business business) {
    return _buildModernCard([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusIndicator(
            l10n.active,
            business.status == 'approved',
            Icons.check_circle,
            business.status == 'approved'
                ? Colors.green
                : Theme.of(context).colorScheme.error,
          ),
          _buildStatusIndicator(
            l10n.verified,
            business.status == 'approved',
            Icons.verified,
            business.status == 'approved' ? const Color(0xFF007fff) : Colors.grey,
          ),
        ],
      ),
    ]);
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {bool isMultiline = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3399FF).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF3399FF).withAlpha(51),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3399FF),
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
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value.isNotEmpty ? value : 'Not provided',
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build circular business photo widget for header
  Widget _buildCircularBusinessPhoto(String? businessPhotoUrl) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withAlpha(77),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: businessPhotoUrl != null && businessPhotoUrl.isNotEmpty
            ? Image.network(
                businessPhotoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to default icon if image fails to load
                  return _buildCircularDefaultIcon();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  );
                },
              )
            : _buildCircularDefaultIcon(),
      ),
    );
  }

  // Build circular default business icon for header
  Widget _buildCircularDefaultIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.business,
        size: 30,
        color: Colors.white,
      ),
    );
  }

  Widget _buildModernCard(List<Widget> children) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withAlpha(38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isActive, IconData icon, Color color) {
    return Row(
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
    );
  }
}
