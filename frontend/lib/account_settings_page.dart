import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/business.dart';

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
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? _userData;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _ownerNameController = TextEditingController();
    _addressController = TextEditingController();

    // Simulate a future where the user data is fetched
    Future.delayed(Duration.zero, () {
      setState(() {
        _isInitializing = false;
      });

      // Load user data after authentication is verified
      _loadUserData();
    });
  }

  void _loadUserData() {
    // Here you would load the user data from your backend or state management
    // For now, we use dummy data
    setState(() {
      _userData = {
        'business_name': 'My Business',
        'owner_name': 'John Doe',
        'email': 'john.doe@example.com',
        'address': '123 Main St, Anytown, USA',
      };
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      // Here you would ideally upload the image to your backend
      // and update the businessPhotoUrl. For now, we just update the UI.
    }
  }

  String _formatAddress(Map<String, dynamic>? address) {
    if (address == null) {
      return '';
    }

    final street = address['street'] ?? '';
    final city = address['city'] ?? '';
    final state = address['state'] ?? '';
    final zip = address['zip'] ?? '';

    return '$street, $city, $state $zip';
  }

  Widget _buildAccountOverviewCard(AppLocalizations l10n, ThemeData theme) {
    final businessName = _userData?['business_name'] ?? 'Business';
    final ownerName = _userData?['owner_name'] ?? 'Owner';
    final email = _userData?['email'] ?? '';
    final businessPhotoUrl = widget.business.businessPhotoUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        image: businessPhotoUrl != null && businessPhotoUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(businessPhotoUrl),
                fit: BoxFit.cover,
              )
            : null,
        gradient: businessPhotoUrl == null || businessPhotoUrl.isEmpty
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3399FF),
                  Color(0xFF00C1E8),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3399FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.9),
                child: Text(
                  businessName.isNotEmpty ? businessName[0].toUpperCase() : 'B',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF001133),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.white),
                onPressed: _pickImage,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            businessName,
            style: theme.textTheme.headline6!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            ownerName,
            style: theme.textTheme.subtitle1!.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: theme.textTheme.bodyText2!.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatAddress(_userData?['address']),
            style: theme.textTheme.bodyText2!.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountSettings),
      ),
      body: _isInitializing
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAccountOverviewCard(l10n, theme),
                  const SizedBox(height: 24),
                  // ... other settings widgets
                ],
              ),
            ),
    );
  }
}
