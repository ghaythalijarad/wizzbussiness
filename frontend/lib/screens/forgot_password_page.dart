import 'package:flutter/material.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import 'package:hadhir_business/services/auth_service.dart';
import 'package:hadhir_business/widgets/wizz_business_text_form_field.dart';
import 'package:hadhir_business/widgets/wizz_business_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _otpRequested = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = null;
      });

      final result =
          await AuthService.requestOtp(_emailController.text.trim(), 'email');

      setState(() {
        _isLoading = false;
        _otpRequested = result['success'];
        _message = result['message'];
      });
    }
  }

  Future<void> _resetWithOtp() async {
    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        setState(() {
          _message = AppLocalizations.of(context)!.passwordMismatch;
          _isSuccess = false;
        });
        return;
      }
      setState(() {
        _isLoading = true;
        _message = null;
      });

      final result = await AuthService.resetPasswordWithOtp(
        _emailController.text.trim(),
        'email',
        _otpController.text.trim(),
        _newPasswordController.text,
      );

      setState(() {
        _isLoading = false;
        _isSuccess = result['success'];
        _message = result['message'];
      });

      if (_isSuccess) _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.emailSent),
          content: Text(
            AppLocalizations.of(context)!.passwordResetLinkSent,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to login
              },
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.forgotPassword),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                _otpRequested ? loc.enterOtp : loc.resetYourPassword,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (!_otpRequested) ...[
                WizzBusinessTextFormField(
                  controller: _emailController,
                  labelText: loc.emailOrPhone,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc.pleaseEnterEmailAddress;
                    }
                    return null;
                  },
                ),
              ] else ...[
                WizzBusinessTextFormField(
                  controller: _otpController,
                  labelText: loc.enterOtp,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: (value) => (value == null || value.isEmpty)
                      ? loc.pleaseEnterOtp
                      : null,
                ),
                const SizedBox(height: 16),
                WizzBusinessTextFormField(
                  controller: _newPasswordController,
                  labelText: loc.newPassword,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock),
                  validator: (value) => (value == null || value.isEmpty)
                      ? loc.pleaseEnterPassword
                      : null,
                ),
                const SizedBox(height: 16),
                WizzBusinessTextFormField(
                  controller: _confirmPasswordController,
                  labelText: loc.confirmNewPassword,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock),
                  validator: (value) => (value == null || value.isEmpty)
                      ? loc.pleaseConfirmPassword
                      : null,
                ),
              ],
              const SizedBox(height: 24),
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
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : WizzBusinessButton(
                      onPressed: _otpRequested ? _resetWithOtp : _requestOtp,
                      text: _otpRequested ? loc.resetPassword : loc.sendOtp,
                    ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.backToLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
