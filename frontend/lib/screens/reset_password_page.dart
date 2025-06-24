import 'package:flutter/material.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import 'package:hadhir_business/services/auth_service.dart';
import 'package:hadhir_business/widgets/wizz_business_button.dart';
import 'package:hadhir_business/widgets/wizz_business_text_form_field.dart';
import '../screens/login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;
  final Function(Locale) onLanguageChanged;

  const ResetPasswordPage({
    super.key,
    required this.token,
    required this.onLanguageChanged,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = null;
      });

      final result = await AuthService.resetPassword(
        widget.token,
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
        _message = result['message'];
        _isSuccess = result['success'];
      });

      if (_isSuccess) {
        _showSuccessDialog();
      }
    }
  }

  void _showSuccessDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc.passwordResetSuccessful),
          content: Text(loc.passwordResetSuccessMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LoginPage(onLanguageChanged: widget.onLanguageChanged),
                  ),
                  (route) => false, // Remove all previous routes
                );
              },
              child: Text(loc.goToLogin),
            ),
          ],
        );
      },
    );
  }

  String? _validatePassword(String? value) {
    final loc = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return loc.pleaseEnterPassword;
    }
    if (value.length < 8) {
      return loc.passwordLengthRequirement;
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return loc.passwordComplexityRequirement;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final loc = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return loc.pleaseConfirmPassword;
    }
    if (value != _passwordController.text) {
      return loc.passwordsDoNotMatch;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.resetPassword),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Header
              Text(
                loc.setNewPassword,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                loc.enterNewPasswordBelow,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // New Password Field
              WizzBusinessTextFormField(
                controller: _passwordController,
                labelText: loc.newPassword,
                obscureText: _obscurePassword,
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              WizzBusinessTextFormField(
                controller: _confirmPasswordController,
                labelText: loc.confirmNewPassword,
                obscureText: _obscureConfirmPassword,
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 24),

              // Password Requirements
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.passwordRequirements,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.passwordRequirementsDetails,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error/Success Message
              if (_message != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSuccess ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isSuccess ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _isSuccess ? Colors.green[700] : Colors.red[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Reset Password Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : WizzBusinessButton(
                      onPressed: _resetPassword,
                      text: loc.resetPassword,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
