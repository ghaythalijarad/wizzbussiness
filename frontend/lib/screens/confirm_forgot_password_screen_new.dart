import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/design_system/typography_system.dart';
import '../services/app_auth_service.dart';

class ConfirmForgotPasswordScreen extends StatefulWidget {
  final String email;

  const ConfirmForgotPasswordScreen({super.key, required this.email});

  @override
  State<ConfirmForgotPasswordScreen> createState() =>
      _ConfirmForgotPasswordScreenState();
}

class _ConfirmForgotPasswordScreenState
    extends State<ConfirmForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AppAuthService.confirmForgotPassword(
        email: widget.email,
        confirmationCode: _codeController.text.trim(),
        newPassword: _passwordController.text,
      );

      if (result.success) {
        // Navigate back to login screen and show success message
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Password reset successfully! You can now sign in with your new password.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to reset password: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AppAuthService.forgotPassword(email: widget.email);
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
                  'Confirm Reset Password',
                  style: TypographySystem.headlineSmall.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Enter verification code and new password',
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
                AppColors.primary.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
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
            Icons.verified_user,
            size: GoldenRatio.xxxl,
            color: AppColors.primary,
          ),
        ),

        // Header Section
        Container(
          padding: EdgeInsets.all(GoldenRatio.spacing24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.05),
                AppColors.primary.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Enter Verification Code',
                style: TypographySystem.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: GoldenRatio.spacing12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TypographySystem.bodyLarge.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: 'We sent a verification code to\n',
                    ),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: GoldenRatio.xl),

        // Form
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Verification Code Field
              _buildModernTextField(
                controller: _codeController,
                label: 'Verification Code',
                hint: 'Enter 6-digit code',
                icon: Icons.security,
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter verification code';
                  }
                  if (value.length != 6) {
                    return 'Code must be 6 digits';
                  }
                  return null;
                },
              ),

              SizedBox(height: GoldenRatio.spacing20),

              // New Password Field
              _buildModernTextField(
                controller: _passwordController,
                label: 'New Password',
                hint: 'Enter your new password',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.primary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),

              SizedBox(height: GoldenRatio.spacing20),

              // Confirm Password Field
              _buildModernTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Confirm your new password',
                icon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: AppColors.primary,
                  ),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              SizedBox(height: GoldenRatio.xl),

              // Reset Password Button
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
                    onTap: _isLoading ? null : _resetPassword,
                    borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: GoldenRatio.spacing18),
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
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: GoldenRatio.spacing20,
                            ),
                            SizedBox(width: GoldenRatio.spacing12),
                          ],
                          Text(
                            _isLoading ? 'Resetting...' : 'Reset Password',
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

        // Error Message
        if (_errorMessage != null) ...[
          SizedBox(height: GoldenRatio.spacing24),
          Container(
            padding: EdgeInsets.all(GoldenRatio.spacing16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
              border: Border.all(
                color: AppColors.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: GoldenRatio.spacing24,
                ),
                SizedBox(width: GoldenRatio.spacing12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TypographySystem.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: GoldenRatio.xl),

        // Resend Code Button
        Center(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _resendCode,
                borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: GoldenRatio.spacing24,
                    vertical: GoldenRatio.spacing12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        size: GoldenRatio.spacing18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: GoldenRatio.spacing8),
                      Text(
                        'Resend Code',
                        style: TypographySystem.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: GoldenRatio.xl),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
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
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength: maxLength,
        style: TypographySystem.bodyLarge.copyWith(
          color: AppColors.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          counterText: '',
          prefixIcon: Container(
            margin: EdgeInsets.all(GoldenRatio.spacing12),
            padding: EdgeInsets.all(GoldenRatio.spacing8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: GoldenRatio.spacing20,
            ),
          ),
          suffixIcon: suffixIcon,
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
              color: AppColors.primary,
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
            color: AppColors.primary,
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
        validator: validator,
      ),
    );
  }
}
