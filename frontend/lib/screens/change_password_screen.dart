import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/app_auth_service.dart';
import '../widgets/wizz_business_text_form_field.dart';
import '../widgets/wizz_business_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AppAuthService.changePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.passwordChangedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
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
            content: Text('Error changing password: $e'),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.changePassword),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Current Password
                WizzBusinessTextFormField(
                  controller: _currentPasswordController,
                  labelText: l10n.password,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterYourPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // New Password
                WizzBusinessTextFormField(
                  controller: _newPasswordController,
                  labelText: l10n.changePassword,
                  obscureText: true,
                  validator: (value) {
                    final pwd = (value ?? '');
                    if (pwd.isEmpty) {
                      return l10n.passwordRequired;
                    }
                    final lengthOk = pwd.length >= 8;
                    final hasLower = RegExp(r'(?=.*[a-z])').hasMatch(pwd);
                    final hasUpper = RegExp(r'(?=.*[A-Z])').hasMatch(pwd);
                    final hasNumber = RegExp(r'(?=.*\d)').hasMatch(pwd);
                    final hasSpecial = RegExp(r'(?=.*[!@#\$%^&*(),.?":{}|<>])').hasMatch(pwd);
                    final valid = lengthOk && hasLower && hasUpper && hasNumber && hasSpecial;
                    if (!valid) {
                      return '${l10n.passwordRequirementsTitle}\n${l10n.passwordRequirementsBullets}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm New Password
                WizzBusinessTextFormField(
                  controller: _confirmPasswordController,
                  labelText: l10n.confirmPassword,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.confirmPasswordRequired;
                    }
                    if (value != _newPasswordController.text) {
                      return l10n.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Change Password Button
                WizzBusinessButton(
                  onPressed: _isLoading ? null : _changePassword,
                  text: l10n.changePassword,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
