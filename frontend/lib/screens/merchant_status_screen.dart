import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/business.dart';

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStatusColor().withOpacity(0.1),
                ),
                child: Icon(
                  _getStatusIcon(),
                  size: 64,
                  color: _getStatusColor(),
                ),
              ),
              const SizedBox(height: 32),

              // Status Title
              Text(
                _getStatusTitle(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Status Message
              Text(
                message ?? _getDefaultMessage(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Action Buttons
              if (status == 'pending') ...[
                _buildInfoCard(
                  'What happens next?',
                  'Our team will review your application within 1-2 business days. We may contact you if additional information is needed.',
                  Icons.info_outline,
                  Colors.blue,
                ),
                const SizedBox(height: 24),
              ] else if (status == 'rejected') ...[
                _buildInfoCard(
                  'Why was my application rejected?',
                  'Common reasons include incomplete documentation, business verification issues, or policy violations. Contact support for details.',
                  Icons.help_outline,
                  Colors.orange,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _reapply(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reapply',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (status == 'suspended') ...[
                _buildInfoCard(
                  'Account Suspended',
                  'Your account has been temporarily suspended. This may be due to policy violations or security concerns. Contact support for assistance.',
                  Icons.warning_outlined,
                  Colors.orange,
                ),
                const SizedBox(height: 24),
              ],

              // Contact Support Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _contactSupport(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Contact Support',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Back to Login
              TextButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                ),
                child: const Text(
                  'Back to Login',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.schedule;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'suspended':
        return Icons.block;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusTitle() {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Application Approved!';
      case 'pending':
        return 'Application Under Review';
      case 'rejected':
        return 'Application Rejected';
      case 'suspended':
        return 'Account Suspended';
      default:
        return 'Application Status';
    }
  }

  String _getDefaultMessage() {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Congratulations! Your merchant application has been approved. You can now start receiving orders.';
      case 'pending':
        return 'Thank you for submitting your application. We are currently reviewing your information and will notify you once the process is complete.';
      case 'rejected':
        return 'Unfortunately, your application has been rejected. Please review the requirements and consider reapplying.';
      case 'suspended':
        return 'Your merchant account has been suspended. Please contact our support team for more information.';
      default:
        return 'Please contact support for more information about your application status.';
    }
  }

  void _reapply(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/registration');
  }

  void _contactSupport(BuildContext context) {
    // TODO: Implement contact support functionality
    // This could open email client, phone dialer, or in-app chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support contact feature coming soon!'),
      ),
    );
  }
}
