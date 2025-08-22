import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../l10n/app_localizations.dart';
import '../models/business.dart';
import 'signin_screen.dart';
import 'signup_screen.dart';
import 'dashboards/business_dashboard.dart';
import 'status/pending_approval_screen.dart';
import 'status/rejected_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final Map<String, dynamic>? businessData; // Add business data to preserve it

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    this.businessData,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _verificationController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _verificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.emailVerificationTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Header
                _buildHeader(l10n),
                const SizedBox(height: 48),

                // Verification Code Input
                CustomTextField(
                  controller: _verificationController,
                  labelText: l10n.verificationCode,
                  prefixIcon: Icons.security_outlined,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return l10n.verificationCodeRequired;
                    }
                    if (value!.length != 6) {
                      return l10n.verificationCodeMustBe6Digits;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Verify Button
                CustomButton(
                  text: l10n.verifyYourEmail,
                  onPressed: _isLoading ? null : _verifyEmail,
                  isLoading: _isLoading,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                const SizedBox(height: 24),

                // Resend Code
                _buildResendSection(l10n),
                const SizedBox(height: 24),

                // Back to Login
                _buildBackToLoginLink(l10n),

                const SizedBox(height: 16),

                // Start Over
                _buildStartOverLink(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.email_outlined,
            color: Theme.of(context).primaryColor,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.verifyYourEmail,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.verificationCodeSentTo(widget.email),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResendSection(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.didntReceiveCode,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isResending ? null : _resendCode,
          child: _isResending
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                )
              : Text(
                  l10n.resendVerificationCode,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBackToLoginLink(AppLocalizations l10n) {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SignInScreen(),
            ),
          );
        },
        child: Text(
          l10n.back,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStartOverLink(AppLocalizations l10n) {
    return Center(
      child: TextButton(
        onPressed: () {
          _showEmailChangeDialog(l10n);
        },
        child: Text(
          l10n.wrongEmailChangeIt,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _verifyEmail() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AppAuthService.confirmRegistration(
        email: widget.email,
        confirmationCode: _verificationController.text.trim(),
      );

      if (result.success) {
        _showSuccessSnackBar(result.message ?? 'Verification successful');

        // Check if we have user and business data for auto-navigation
        if (result.business != null) {
          final business =
              Business.fromJson(Map<String, dynamic>.from(result.business!));

          switch (business.status.toLowerCase()) {
            case 'approved':
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const BusinessDashboard()),
                (route) => false,
              );
              break;
            case 'pending_review':
            case 'pending':
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const PendingApprovalScreen()),
                (route) => false,
              );
              break;
            case 'rejected':
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const RejectedScreen()),
                (route) => false,
              );
              break;
            default:
              // Fallback to sign in screen if status is unknown
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SignInScreen()),
                (route) => false,
              );
          }
        } else {
          // Original flow - navigate to sign in with a friendly prompt
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const SignInScreen(
                noticeMessage: 'Account verified. Please sign in to continue.',
              ),
            ),
            (route) => false,
          );
        }
      } else {
        _showErrorSnackBar(result.message ?? 'Verification failed');
      }
    } catch (e) {
      // Show specific error message from backend
      final errorMessage = e.toString();
      if (errorMessage.contains('Invalid verification code')) {
        _showErrorSnackBar(
            'Invalid verification code. Please check and try again.');
      } else if (errorMessage.contains('expired')) {
        _showErrorSnackBar(
            'Verification code has expired. Please request a new one.');
      } else {
        _showErrorSnackBar(errorMessage.replaceFirst('Exception: ', ''));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isResending = true;
    });

    try {
      await AppAuthService.resendRegistrationCode(email: widget.email);
      _showSuccessSnackBar(l10n.verificationCodeSentToEmail);
    } catch (e) {
      // If backend throws with a message, surface it
      final msg = e.toString();
      if (msg.contains('already verified') || msg.contains('409')) {
        _showErrorSnackBar(l10n.accountAlreadyVerifiedPleaseSignIn);
      } else if (msg.contains('Too many attempts') || msg.contains('429')) {
        _showErrorSnackBar(l10n.tooManyAttemptsPleaseWait);
      } else if (msg.contains('No account') || msg.contains('404')) {
        _showErrorSnackBar(l10n.noAccountFoundForThisEmail);
      } else {
        _showErrorSnackBar(l10n.failedToResendCode);
      }
    } finally {
      // Add small cooldown to avoid rapid-fire resends
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _showEmailChangeDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changeEmailAddressTitle),
        content: Text(l10n.changeEmailAddressMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const SignUpScreen(),
                ),
                (route) => false,
              );
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
