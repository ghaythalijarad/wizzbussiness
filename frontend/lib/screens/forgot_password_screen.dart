import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_auth_service.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCodeSent = false;

  // Step 1
  String _email = '';
  // Step 2
  String _confirmationCode = '';
  String _newPassword = '';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      if (!_isCodeSent) {
        final response = await AppAuthService.forgotPassword(email: _email);
        if (response.success) {
          setState(() { _isCodeSent = true; });
        } else {
          setState(() { _errorMessage = response.message; });
        }
      } else {
        final response = await AppAuthService.confirmForgotPassword(
          email: _email,
          newPassword: _newPassword,
          confirmationCode: _confirmationCode,
        );
        if (response.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.message), backgroundColor: Colors.green)
            );
            Navigator.of(context).pop();
          }
        } else {
          setState(() { _errorMessage = response.message; });
        }
      }
    } catch (e) {
      setState(() { _errorMessage = e.toString(); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title:
            Text(_isCodeSent ? loc.changePassword : loc.forgotPasswordQuestion),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Icon(
                _isCodeSent ? Icons.security : Icons.lock_reset,
                size: 64,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                _isCodeSent
                    ? loc.enterTheCodeSentToYourEmail
                    : loc.forgotPasswordQuestion,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isCodeSent) ...[
                          TextFormField(
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: loc.email,
                              prefixIcon: Icon(Icons.email_outlined, color: theme.primaryColor),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9@._%+-]')),
                            ],
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return loc.pleaseEnterYourEmail;
                              final trimmed = v.trim();
                              final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                              if (!emailRegex.hasMatch(trimmed))
                                return loc.invalidEmailFormat;
                              return null;
                            },
                            onSaved: (v) => _email = v!.trim(),
                          ),
                        ] else ...[
                          TextFormField(
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: loc.verificationCode,
                              prefixIcon: Icon(Icons.vpn_key, color: theme.primaryColor),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.isEmpty
                                ? loc.verificationCodeRequired
                                : (v.length != 6
                                    ? loc.verificationCodeMustBe6Digits
                                    : null),
                            onSaved: (v) => _confirmationCode = v!.trim(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: loc
                                  .enterYourPassword, // Using existing key instead of non-existent newPassword
                              prefixIcon: Icon(Icons.lock_outline, color: theme.primaryColor),
                            ),
                            obscureText: true,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return loc.pleaseEnterYourPassword;
                              final pwd = v;
                              final hasMinLen = pwd.length >= 8;
                              final hasUpper = RegExp(r'[A-Z]').hasMatch(pwd);
                              final hasLower = RegExp(r'[a-z]').hasMatch(pwd);
                              final hasDigit = RegExp(r'[0-9]').hasMatch(pwd);
                              final hasSpecial =
                                  RegExp(r'[!@#\$%\^&*()_+\-\[\]{}|;:,./<>?~`]')
                                      .hasMatch(pwd);
                              if (!(hasMinLen &&
                                  hasUpper &&
                                  hasLower &&
                                  hasDigit &&
                                  hasSpecial)) {
                                return loc.weakPassword;
                              }
                              return null;
                            },
                            onSaved: (v) => _newPassword = v!,
                          ),
                        ],
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                              ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                                : Text(!_isCodeSent
                                    ? loc.resendVerificationCode
                                    : loc.changePassword),
                          ),
                        ),
                        if (_isCodeSent) ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => setState(() => _isCodeSent = false),
                            child: Text(loc.changeEmail,
                                style: TextStyle(color: theme.primaryColor)),
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
