import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/theme/app_colors.dart';
import '../models/business.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/image_upload_service.dart';
import '../providers/business_provider.dart';
import '../providers/session_provider.dart';
import 'login_page.dart';

class BusinessDetailsScreen extends ConsumerStatefulWidget {
  final Business business;

  const BusinessDetailsScreen({Key? key, required this.business})
      : super(key: key);

  @override
  ConsumerState<BusinessDetailsScreen> createState() =>
      _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends ConsumerState<BusinessDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _businessNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _descriptionController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeControllers();
  }

  void _initializeControllers() {
    final business = widget.business;
    _businessNameController = TextEditingController(text: business.name);
    _ownerNameController =
        TextEditingController(text: business.ownerName ?? '');
    _phoneController = TextEditingController(text: business.phone ?? '');
    _emailController = TextEditingController(text: business.email);
    _descriptionController =
        TextEditingController(text: business.description ?? '');
    _websiteController = TextEditingController(text: business.website ?? '');
    _addressController = TextEditingController(text: business.address ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Update Business Photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.blue),
                  ),
                  title: const Text('Choose from Gallery'),
                  subtitle: const Text('Select an existing photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImageFromGallery();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.green),
                  ),
                  title: const Text('Take Photo'),
                  subtitle: const Text('Use camera to take a new photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImageFromCamera();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    } catch (e) {
      _showSnackBar('Error selecting photo option: $e', isError: true);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _uploadBusinessPhoto();
      }
    } catch (e) {
      _showSnackBar('Error picking image from gallery: $e', isError: true);
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _uploadBusinessPhoto();
      }
    } catch (e) {
      _showSnackBar('Error taking photo: $e', isError: true);
    }
  }

  Future<void> _uploadBusinessPhoto() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final session = ref.read(sessionProvider);
      if (!session.isAuthenticated) {
        _showAuthenticationRequiredDialog();
        return;
      }

      // Use static method with correct signature
      final response =
          await ImageUploadService.uploadBusinessPhoto(_selectedImage!);
      final photoUrl = response['url'] as String;

      final apiService = ApiService();
      await apiService.updateBusinessPhoto(widget.business.id, photoUrl);

      // Update business object locally
      widget.business.updateProfile(businessPhotoUrl: photoUrl);

      // Refresh business provider
      ref.invalidate(businessProvider);

      setState(() {
        _selectedImage = null;
        _isUploadingPhoto = false;
      });

      _showSnackBar('Business photo updated successfully!');
    } catch (e) {
      setState(() {
        _selectedImage = null;
        _isUploadingPhoto = false;
      });
      _showSnackBar('Failed to upload photo: $e', isError: true);
    }
  }

  Future<void> _saveBusinessProfile() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final session = ref.read(sessionProvider);
      if (!session.isAuthenticated) {
        _showAuthenticationRequiredDialog();
        return;
      }

      final apiService = ApiService();
      final updateData = {
        'businessName': _businessNameController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'description': _descriptionController.text.trim(),
        'website': _websiteController.text.trim(),
        'address': _addressController.text.trim(),
      };

      await apiService.updateBusinessProfile(widget.business.id, updateData);

      // Update business object locally
      widget.business.updateProfile(
        name: _businessNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        phone: _phoneController.text.trim(),
        description: _descriptionController.text.trim(),
        website: _websiteController.text.trim(),
        address: _addressController.text.trim(),
      );

      // Refresh business provider
      ref.invalidate(businessProvider);

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      _showSnackBar('Business profile updated successfully!');
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showSnackBar('Failed to update profile: $e', isError: true);
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset controllers if canceling edit
        _initializeControllers();
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showAuthenticationRequiredDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.security,
          color: AppColors.primary,
          size: 48,
        ),
        title: Text(
          'Authentication Required',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          loc.pleaseSignInToAccessLocationSettings,
          style: TextStyle(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context, rootNavigator: true).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(loc.signIn),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final business = widget.business;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildBusinessHeader(business),
              ),
              actions: [
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _toggleEditMode,
                  ),
                if (_isEditing) ...[
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleEditMode,
                  ),
                  IconButton(
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    onPressed: _isSaving ? null : _saveBusinessProfile,
                  ),
                ],
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: [
                  Tab(icon: const Icon(Icons.info), text: 'Details'),
                  Tab(icon: const Icon(Icons.access_time), text: 'Hours'),
                  Tab(icon: const Icon(Icons.location_on), text: l10n.location),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDetailsTab(l10n, business),
            _buildHoursTab(l10n, business),
            _buildLocationTab(l10n, business),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHeader(Business business) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _HeaderPatternPainter(),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80), // Account for app bar
                Row(
                  children: [
                    // Business Photo
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _selectedImage != null
                                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                : business.businessPhotoUrl != null &&
                                        business.businessPhotoUrl!.isNotEmpty
                                    ? Image.network(
                                        business.businessPhotoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return _buildDefaultBusinessIcon();
                                        },
                                      )
                                    : _buildDefaultBusinessIcon(),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUploadingPhoto ? null : _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _isUploadingPhoto
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    // Business Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              business.businessType.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Status indicators
                          Row(
                            children: [
                              _buildStatusChip(
                                business.status == 'approved'
                                    ? 'Active'
                                    : 'Pending',
                                business.status == 'approved',
                              ),
                              const SizedBox(width: 8),
                              _buildStatusChip('Verified', true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultBusinessIcon() {
    return Container(
      color: Colors.white.withOpacity(0.1),
      child: const Icon(
        Icons.business,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(AppLocalizations l10n, Business business) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information Card
          _buildModernCard(
            title: l10n.businessInformation,
            icon: Icons.business,
            children: [
              _buildFormField(
                label: l10n.businessName,
                controller: _businessNameController,
                icon: Icons.store,
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: l10n.ownerName,
                controller: _ownerNameController,
                icon: Icons.person,
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: l10n.emailAddress,
                controller: _emailController,
                icon: Icons.email,
                enabled: false, // Email should not be editable
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: l10n.phoneNumber,
                controller: _phoneController,
                icon: Icons.phone,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Business Details Card
          _buildModernCard(
            title: 'Business Details',
            icon: Icons.description,
            children: [
              _buildFormField(
                label: 'Description',
                controller: _descriptionController,
                icon: Icons.description,
                enabled: _isEditing,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Website',
                controller: _websiteController,
                icon: Icons.language,
                enabled: _isEditing,
                keyboardType: TextInputType.url,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Business Statistics Card
          _buildModernCard(
            title: 'Statistics',
            icon: Icons.analytics,
            children: [
              _buildStatItem('Total Orders', '1,234'),
              const SizedBox(height: 12),
              _buildStatItem('Rating', '4.8 ⭐'),
              const SizedBox(height: 12),
              _buildStatItem('Reviews', '256'),
              const SizedBox(height: 12),
              _buildStatItem('Member Since', 'January 2024'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHoursTab(AppLocalizations l10n, Business business) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildModernCard(
            title: 'Working Hours',
            icon: Icons.access_time,
            children: [
              Text(
                'Configure your business operating hours to let customers know when you\'re available.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              _buildWorkingHoursSection(business),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showSnackBar('Working hours configuration coming soon!');
                  },
                  icon: const Icon(Icons.edit),
                  label: Text('Edit Working Hours'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTab(AppLocalizations l10n, Business business) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildModernCard(
            title: l10n.businessLocation,
            icon: Icons.location_on,
            children: [
              _buildFormField(
                label: l10n.addressLabel,
                controller: _addressController,
                icon: Icons.location_on,
                enabled: _isEditing,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              if (business.latitude != null && business.longitude != null) ...[
                _buildInfoRow(
                  'Latitude',
                  business.latitude!.toStringAsFixed(6),
                  Icons.my_location,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Longitude',
                  business.longitude!.toStringAsFixed(6),
                  Icons.my_location,
                ),
                const SizedBox(height: 20),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showSnackBar(
                        'Location settings configuration coming soon!');
                  },
                  icon: const Icon(Icons.edit_location),
                  label: Text('Edit Location Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(enabled ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: enabled
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.5),
            size: 20,
          ),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: TextStyle(
        color: enabled ? Colors.black87 : Colors.grey.shade600,
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingHoursSection(Business business) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return Column(
      children: days.map((day) {
        // This is mock data - replace with actual business hours
        final isOpen = day != 'Sunday';
        final hours = isOpen ? '9:00 AM - 6:00 PM' : 'Closed';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hours,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOpen ? Colors.green[700] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw geometric pattern
    for (int i = 0; i < size.width ~/ 20; i++) {
      for (int j = 0; j < size.height ~/ 20; j++) {
        if ((i + j) % 3 == 0) {
          canvas.drawCircle(
            Offset(i * 20.0 + 10, j * 20.0 + 10),
            2,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
