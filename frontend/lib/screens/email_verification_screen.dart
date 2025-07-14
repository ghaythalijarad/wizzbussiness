import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../l10n/app_localizations.dart';
import 'signin_screen.dart';
import 'signup_screen.dart';

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
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return l10n.verificationCodeRequired;
                    }
                    if (value!.length != 6) {
                      return 'Verification code must be 6 digits';
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
          "Didn't receive the code?",
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
                  'Resend Code',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
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
          'Back to Login',
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
          'Wrong email? Change it',
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
      final result = await AppAuthService.confirmSignUp(
        username: widget.email,
        code: _verificationController.text.trim(),
      );

      if (result.success) {
        _showSuccessSnackBar(result.message ?? 'Verification successful');

        // Navigate to sign in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SignInScreen(),
          ),
        );
      } else {
        _showErrorSnackBar(result.message ?? 'Verification failed');
      }
    } catch (e) {
      _showErrorSnackBar(l10n.verificationFailed);
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
      await AppAuthService.resendSignUpCode(username: widget.email);
      _showSuccessSnackBar('Verification code resent successfully');
    } catch (e) {
      _showErrorSnackBar(l10n.failedToResendCode);
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  Future<void> _showEmailChangeDialog(AppLocalizations l10n) async {
    final emailController = TextEditingController(text: widget.email);
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Email Address'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter your correct email address to receive a new verification code.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: emailController,
                  labelText: l10n.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Email is required';
                    }
                    if (!_isValidEmail(value!)) {
                      return 'Invalid email format';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  _changeEmailAndResend(emailController.text.trim());
                }
              },
              child: Text('Change & Resend Code'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeEmailAndResend(String newEmail) async {
    if (newEmail == widget.email) {
      _showErrorSnackBar('Please enter a different email address');
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      // For now, we'll navigate back to signup with the new email
      // In a full implementation, you'd want to update the backend
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const SignUpScreen(),
        ),
        (Route<dynamic> route) => false,
      );

      _showSuccessSnackBar(
          'Please complete registration with your correct email');
    } catch (e) {
      _showErrorSnackBar('Failed to change email. Please try again.');
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
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
