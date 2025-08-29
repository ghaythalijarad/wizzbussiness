import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/design_system/typography_system.dart';
import '../services/app_auth_service.dart';
import 'confirm_forgot_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundVariant,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.secondary.withOpacity(0.03),
              AppColors.background,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(GoldenRatio.spacing24),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: GoldenRatio.spacing20,
        vertical: GoldenRatio.spacing16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.04),
            blurRadius: GoldenRatio.spacing12,
            offset: Offset(0, GoldenRatio.spacing4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SizedBox(width: GoldenRatio.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset Password',
                  style: TypographySystem.headlineSmall.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Recover your account access',
                  style: TypographySystem.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: GoldenRatio.spacing20),

        // Icon with modern styling
        Container(
          padding: EdgeInsets.all(GoldenRatio.spacing24),
          margin: EdgeInsets.only(bottom: GoldenRatio.spacing24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.warning.withOpacity(0.1),
                AppColors.warning.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
            border: Border.all(
              color: AppColors.warning.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.08),
                blurRadius: GoldenRatio.spacing20,
                offset: Offset(0, GoldenRatio.spacing8),
              ),
            ],
          ),
          child: Icon(
            _emailSent ? Icons.mark_email_read : Icons.lock_reset,
            size: GoldenRatio.xxxl,
            color: AppColors.warning,
          ),
        ),
        
        // Header Section
        Container(
          padding: EdgeInsets.all(GoldenRatio.spacing24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.warning.withOpacity(0.05),
                AppColors.warning.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
            border: Border.all(
              color: AppColors.warning.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                _emailSent ? 'Check Your Email' : 'Forgot Password?',
                style: TypographySystem.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: GoldenRatio.spacing12),
              
              Text(
                _emailSent
                    ? 'We\'ve sent a verification code to your email address. Please check your inbox for the 6-digit code.'
                    : 'Enter your email address and we\'ll send you a verification code to reset your password.',
                style: TypographySystem.bodyLarge.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        SizedBox(height: GoldenRatio.xl),

        if (!_emailSent) ...[
          // Email Form
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildModernTextField(),

                SizedBox(height: GoldenRatio.xl),

                // Send Reset Link Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warning,
                        AppColors.warning.withOpacity(0.8)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warning.withOpacity(0.3),
                        blurRadius: GoldenRatio.spacing16,
                        offset: Offset(0, GoldenRatio.spacing8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _sendResetLink,
                      borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: GoldenRatio.spacing18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoading) ...[
                              SizedBox(
                                width: GoldenRatio.spacing20,
                                height: GoldenRatio.spacing20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: GoldenRatio.spacing12),
                            ] else ...[
                              Icon(
                                Icons.email_outlined,
                                color: Colors.white,
                                size: GoldenRatio.spacing20,
                              ),
                              SizedBox(width: GoldenRatio.spacing12),
                            ],
                            Text(
                              _isLoading ? 'Sending...' : 'Send Reset Code',
                              style: TypographySystem.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Success State - Email Sent
          Container(
            padding: EdgeInsets.all(GoldenRatio.spacing24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withOpacity(0.1),
                  AppColors.success.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
              border: Border.all(
                color: AppColors.success.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.08),
                  blurRadius: GoldenRatio.spacing20,
                  offset: Offset(0, GoldenRatio.spacing8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.mark_email_read,
                  size: GoldenRatio.xxxl,
                  color: AppColors.success,
                ),
                SizedBox(height: GoldenRatio.spacing16),
                Text(
                  'Verification Code Sent!',
                  style: TypographySystem.headlineSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: GoldenRatio.spacing8),
                Text(
                  'Check your spam folder if you don\'t see the code in your inbox.',
                  style: TypographySystem.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          SizedBox(height: GoldenRatio.xl),

          // Continue Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: GoldenRatio.spacing16,
                  offset: Offset(0, GoldenRatio.spacing8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConfirmForgotPasswordScreen(
                        email: _emailController.text,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: GoldenRatio.spacing18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: GoldenRatio.spacing20,
                      ),
                      SizedBox(width: GoldenRatio.spacing12),
                      Text(
                        'Continue to Verification',
                        style: TypographySystem.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],

        SizedBox(height: GoldenRatio.xl),

        // Back to Login
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Remember your password? ',
              style: TypographySystem.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                'Sign In',
                style: TypographySystem.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernTextField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.04),
            blurRadius: GoldenRatio.spacing8,
            offset: Offset(0, GoldenRatio.spacing4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: TypographySystem.bodyLarge.copyWith(
          color: AppColors.onSurface,
        ),
        decoration: InputDecoration(
          labelText: 'Email Address',
          hintText: 'Enter your email',
          prefixIcon: Container(
            margin: EdgeInsets.all(GoldenRatio.spacing12),
            padding: EdgeInsets.all(GoldenRatio.spacing8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
            ),
            child: Icon(
              Icons.email_outlined,
              color: AppColors.warning,
              size: GoldenRatio.spacing20,
            ),
          ),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
            borderSide: BorderSide(
              color: AppColors.warning,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          labelStyle: TypographySystem.bodyMedium.copyWith(
            color: AppColors.warning,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TypographySystem.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: GoldenRatio.spacing20,
            vertical: GoldenRatio.spacing16,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _sendResetLink() async {
    print('🔄 _sendResetLink() called');
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    print('✅ Form validation passed, starting password reset');
    setState(() {
      _isLoading = true;
    });

    try {
      print(
          '📧 Calling AppAuthService.forgotPassword for email: ${_emailController.text.trim()}');
      final result = await AppAuthService.forgotPassword(
        email: _emailController.text.trim(),
      );

      print(
          '📥 AppAuthService.forgotPassword result: success=${result.success}, message=${result.message}');

      if (result.success) {
        // Show success message and navigate to confirmation screen
        if (mounted) {
          print(
              '🔐 Password reset code sent successfully, navigating to confirmation screen');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code sent to your email!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to confirmation screen
          print('🚀 Attempting navigation to ConfirmForgotPasswordScreen');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmForgotPasswordScreen(
                email: _emailController.text.trim(),
              ),
            ),
          ).then((_) {
            print('✅ Navigation to ConfirmForgotPasswordScreen completed');
          });
        }
      } else {
        print('❌ Password reset failed: ${result.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send verification code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ignore: unused_element
  Future<void> _resendResetLink() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AppAuthService.forgotPassword(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success
                ? 'Verification code sent again!'
                : 'Failed to resend code: ${result.message}'),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
