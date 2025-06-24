import 'package:flutter/material.dart';
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
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
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
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
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
          _ownerNameController.text = _userData?['email'] ?? ''; // Using email as owner name for now
          _emailController.text = _userData?['email'] ?? '';
          _phoneController.text = _userData?['phone_number'] ?? '';
          _addressController.text = ''; // Address not available in user model yet
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
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User Information',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _businessNameController,
                                  decoration: InputDecoration(
                                    labelText: l10n.businessName,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _ownerNameController,
                                  decoration: InputDecoration(
                                    labelText: l10n.ownerName,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: l10n.email,
                                    border: const OutlineInputBorder(),
                                  ),
                                  enabled: false, // Email should not be editable
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    labelText: l10n.phoneNumber,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: InputDecoration(
                                    labelText: l10n.businessAddressLabel,
                                    border: const OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Security',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChangePasswordScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.lock),
                                  label: Text(l10n.changePassword),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 48),
                                  ),
                                ),
                              ],
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
