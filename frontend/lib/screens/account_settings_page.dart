import 'package:flutter/material.dart';
import '../models/business.dart';
import '../l10n/app_localizations.dart';
import './change_password_screen.dart';

class AccountSettingsPage extends StatefulWidget {
  final Business business;

  const AccountSettingsPage({Key? key, required this.business})
      : super(key: key);

  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late TextEditingController _businessNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.business.name);
    _ownerNameController =
        TextEditingController(text: widget.business.ownerName);
    _emailController = TextEditingController(text: widget.business.email);
    _phoneController = TextEditingController(text: widget.business.phone);
    _addressController = TextEditingController(text: widget.business.address);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    // TODO: Implement save logic
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountSettings),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: ListView(
            children: [
              TextFormField(
                controller: _businessNameController,
                decoration: InputDecoration(labelText: l10n.businessName),
              ),
              TextFormField(
                controller: _ownerNameController,
                decoration: InputDecoration(labelText: l10n.ownerName),
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: l10n.email),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: l10n.phoneNumber),
              ),
              TextFormField(
                controller: _addressController,
                decoration:
                    InputDecoration(labelText: l10n.businessAddressLabel),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangePasswordScreen(),
                    ),
                  );
                },
                child: Text(l10n.changePassword),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
