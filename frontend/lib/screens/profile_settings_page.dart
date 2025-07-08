import 'package:flutter/material.dart';
import './account_settings_page.dart';
import './pos_settings_page.dart';
import './change_password_screen.dart';
import '../l10n/app_localizations.dart';
import '../models/business.dart';
import '../models/order.dart';
import '../services/app_state.dart';
import '../services/unified_auth_service.dart';
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
      final response = await UnifiedAuthService.getCurrentUser();
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
    final loc = AppLocalizations.of(context)!;
    if (businessType == null) return loc.notSpecified;

    switch (businessType.toLowerCase()) {
      case 'restaurant':
        return loc.restaurant;
      case 'store':
        return loc.store;
      case 'kitchen':
        return loc.kitchen;
      case 'pharmacy':
        return loc.pharmacy;
      default:
        return businessType;
    }
  }

  Widget _buildUserProfileHeader() {
    final loc = AppLocalizations.of(context)!;
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
              loc.errorLoadingProfile,
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
              child: Text(loc.retry),
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
                  color: Colors.white.withValues(alpha: 0.2),
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
                      _userData?['business_name'] ?? loc.businessName,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getBusinessTypeDisplayName(
                            _userData?['business_type']),
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
                loc.active,
                _userData?['is_active'] ?? false,
                _userData?['is_active'] == true ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildStatusChip(
                loc.verified,
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
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
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
            color: Colors.white.withValues(alpha: 0.3),
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
                color: Colors.white.withValues(alpha: 0.3),
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
            color: Colors.white.withValues(alpha: 0.3),
          );
        }
      }),
    );
  }

  Future<void> _signOut() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.signOut),
        content: Text(loc.signOutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.signOut, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await UnifiedAuthService.signOut();
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
