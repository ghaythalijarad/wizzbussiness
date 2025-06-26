import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../models/business.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
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
  late TextEditingController _addressController;

  Map<String, dynamic>? _userData;
  bool _isLoadingUserData = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty text - will be populated after loading user data
    _businessNameController = TextEditingController();
    _ownerNameController = TextEditingController();
    _addressController = TextEditingController();

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUserData = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.getCurrentUser();
      if (response['success'] == true) {
        setState(() {
          _userData = response['user'];
          _isLoadingUserData = false;

          // Update controllers with real user data
          _businessNameController.text = _userData?['business_name'] ?? '';
          _ownerNameController.text = _userData?['owner_name'] ?? '';
          _addressController.text = _formatAddress(_userData?['address']);
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load user data';
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user data: $e';
        _isLoadingUserData = false;
      });
    }
  }

  String _formatAddress(Map<String, dynamic>? address) {
    if (address == null) {
      return '';
    }
    // Construct a formatted address string from the address map
    return 
        '${address['home_address'] ?? ''}, ${address['street'] ?? ''}, ${address['neighborhood'] ?? ''}, ${address['district'] ?? ''}, ${address['city'] ?? ''}, ${address['country'] ?? ''}';
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: _isLoadingUserData
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading user data',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    child: ListView(
                      children: [
                        _buildInfoTile(l10n.ownerName, _userData?['owner_name'] ?? ''),
                        _buildInfoTile(l10n.emailAddress, _userData?['email'] ?? ''),
                        _buildInfoTile(l10n.phoneNumber, _userData?['phone_number'] ?? '', isLtr: true),
                        _buildInfoTile(l10n.businessAddressLabel, _formatAddress(_userData?['address'])),
                        _buildInfoTile(l10n.businessType, _userData?['business_type'] ?? ''),
                        _buildInfoTile(l10n.registrationDate, _formatDate(_userData?['created_at'])),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordScreen(),
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

  Widget _buildInfoTile(String title, String subtitle, {bool isLtr = false}) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        textDirection: isLtr ? ui.TextDirection.ltr : null,
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) {
      return '';
    }
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat.yMMMd().format(dateTime);
    } catch (e) {
      return dateString;
    }
  }
}
