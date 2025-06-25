import 'package:flutter/material.dart';
import './account_settings_page.dart';
import './pos_settings_page.dart';
import './change_password_screen.dart';
import '../l10n/app_localizations.dart';
import '../models/business.dart';
import '../models/order.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
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
            const Text(
              'Error loading profile',
              style: TextStyle(
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
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData?['business_name'] ?? 'Business Name',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getBusinessTypeDisplayName(_userData?['business_type']),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRatingSection(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                _userData?['is_verified'] == true
                    ? const Color(0xFF007fff)
                    : Colors.grey,
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

  Widget _buildRatingSection() {
    final loc = AppLocalizations.of(context)!;
    // Mock rating data - in real app, this would come from userData or API
    final double businessRating = _userData?['rating']?.toDouble() ?? 4.2;
    final int totalReviews = _userData?['total_reviews'] ?? 156;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_rounded,
            color: Colors.amber[300],
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            businessRating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          _buildStarRating(businessRating),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 16,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.rating,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$totalReviews reviews',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        double fillAmount = rating - index;
        if (fillAmount >= 1.0) {
          // Full star
          return Icon(
            Icons.star_rounded,
            size: 14,
            color: Colors.amber[300],
          );
        } else if (fillAmount > 0.0) {
          // Half star
          return Stack(
            children: [
              Icon(
                Icons.star_rounded,
                size: 14,
                color: Colors.white.withOpacity(0.3),
              ),
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: fillAmount,
                  child: Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Colors.amber[300],
                  ),
                ),
              ),
            ],
          );
        } else {
          // Empty star
          return Icon(
            Icons.star_rounded,
            size: 14,
            color: Colors.white.withOpacity(0.3),
          );
        }
      }),
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

  Widget _buildInfoCard(
      String title, String value, IconData icon, Color color) {
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

  void _showLanguageDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.language, size: 24, color: Color(0xFF00C1E8)),
              const SizedBox(width: 8),
              Text(
                loc.selectLanguage,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageTile(
                context: context,
                flag: '🇺🇸',
                name: loc.english,
                locale: const Locale('en'),
              ),
              const Divider(height: 1),
              _buildLanguageTile(
                context: context,
                flag: '🇸🇦',
                name: loc.arabic,
                locale: const Locale('ar'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                loc.cancel,
                style: const TextStyle(color: Color(0xFF00C1E8)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageTile({
    required BuildContext context,
    required String flag,
    required String name,
    required Locale locale,
  }) {
    final currentLocale = Localizations.localeOf(context);
    final isSelected = currentLocale.languageCode == locale.languageCode;

    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name),
      trailing:
          isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () async {
        if (widget.onLanguageChanged != null) {
          widget.onLanguageChanged!(locale);
        }

        // Save the language preference
        await LanguageService.setLanguage(locale.languageCode);

        Navigator.of(context).pop();

        // Show confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                locale.languageCode == 'ar'
                    ? 'تم تغيير اللغة إلى العربية'
                    : 'Language changed to English',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FBFF), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
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
                  leading: const Icon(Icons.lock),
                  title: Text(loc.changePassword),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
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
                  _showLanguageDialog(context);
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
    );
  }
}
