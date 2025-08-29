import 'package:flutter/material.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/design_system/typography_system.dart';
import '../core/theme/app_colors.dart';
import '../models/business.dart';
import '../l10n/app_localizations.dart';
import '../services/app_auth_service.dart';
import 'auth/auth_screen.dart';

class MerchantStatusScreen extends StatelessWidget {
  final String status;
  final String? message;
  final Business? business;

  const MerchantStatusScreen({
    Key? key,
    required this.status,
    this.message,
    this.business,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(GoldenRatio.spacing24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Modern Status Icon with enhanced design
                Container(
                  width: GoldenRatio.xxxl * 1.5,
                  height: GoldenRatio.xxxl * 1.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getStatusColor().withOpacity(0.1),
                        _getStatusColor().withOpacity(0.05),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor().withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    size: GoldenRatio.xxxl,
                    color: _getStatusColor(),
                  ),
                ),
                SizedBox(height: GoldenRatio.spacing24 + GoldenRatio.spacing8),

                // Modern Status Title
                Text(
                  _getStatusTitle(context),
                  style: TypographySystem.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: GoldenRatio.spacing16),

                // Enhanced Status Message
                Container(
                  padding: EdgeInsets.all(GoldenRatio.spacing16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
                    border: Border.all(
                      color: _getStatusColor().withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message ?? _getDefaultMessage(context),
                    style: TypographySystem.bodyLarge.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: GoldenRatio.spacing24 + GoldenRatio.spacing16),

                // Modern Support Section
                _buildModernSupportSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernSupportSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(GoldenRatio.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Need Help?',
            style: TypographySystem.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: GoldenRatio.spacing12),
          Text(
            'Contact our support team if you have any questions.',
            style: TypographySystem.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: GoldenRatio.spacing16),
          TextButton(
            onPressed: () => _navigateToLogin(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: TypographySystem.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      case 'suspended':
        return AppColors.error;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  IconData _getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.access_time;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'suspended':
        return Icons.warning_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusTitle(BuildContext context) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Account Approved';
      case 'pending':
        return 'Application Pending';
      case 'rejected':
        return 'Application Rejected';
      case 'suspended':
        return 'Account Suspended';
      default:
        return 'Unknown Status';
    }
  }

  String _getDefaultMessage(BuildContext context) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Your merchant account has been approved. You can now start using the platform.';
      case 'pending':
        return 'Your application is being reviewed. We will notify you once the review is complete.';
      case 'rejected':
        return 'Your application has been rejected. Please contact support for more information.';
      case 'suspended':
        return 'Your account has been suspended. Please contact support to resolve this issue.';
      default:
        return 'Unknown status detected. Please contact support.';
    }
  }

  void _navigateToLogin(BuildContext context) async {
    try {
      await AppAuthService.signOut();
    } catch (e) {
      // Handle error silently
    }
    
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  }
}
