import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.changePassword),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _oldPasswordController,
                decoration: InputDecoration(labelText: loc.oldPassword),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.pleaseEnterOldPassword;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(labelText: loc.newPassword),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.pleaseEnterNewPassword;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration:
                    InputDecoration(labelText: loc.confirmNewPasswordLabel),
                obscureText: true,
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return loc.passwordsDoNotMatchError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Implement change password logic
                  }
                },
                child: Text(loc.changePassword),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
