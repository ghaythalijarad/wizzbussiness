import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/design_system/typography_system.dart';
import '../core/theme/app_colors.dart';
import '../models/product.dart';
import '../providers/product_provider_riverpod.dart';
import '../widgets/image_picker_widget.dart';
import '../services/image_upload_service.dart';
import '../services/product_service.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final Product product;

  const EditProductScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  
  String? _selectedCategoryId;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isAvailable = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _selectedCategoryId = widget.product.categoryId;
    // Initialize with first image if available
    if (widget.product.imageUrls.isNotEmpty) {
      // Note: This won't work for editing existing images, but sets up structure
    }
    _isAvailable = widget.product.isAvailable;
  }

  Future<void> _pickImage() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Widget _buildModernAppBar(BuildContext context) {
    return Container(
      height: kToolbarHeight + MediaQuery.of(context).padding.top,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primaryDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: GoldenRatio.spacing8,
            offset: Offset(0, GoldenRatio.spacing4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Edit Product',
                    style: TypographySystem.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Update product information',
                    style: TypographySystem.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: GoldenRatio.spacing8),
              child: TextButton.icon(
                onPressed: _deleteProduct,
                icon: const Icon(Icons.delete_outline,
                    color: Colors.white, size: 20),
                label: Text(
                  'Delete',
                  style: TypographySystem.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  padding: EdgeInsets.symmetric(
                    horizontal: GoldenRatio.spacing12,
                    vertical: GoldenRatio.spacing8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GoldenRatio.spacing8),
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    int? maxLines,
    Widget? prefixIcon,
    String? prefixText,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: GoldenRatio.spacing16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        style: TypographySystem.bodyLarge.copyWith(
          color: AppColors.onSurface,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefixIcon,
          prefixText: prefixText,
          labelStyle: TypographySystem.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          hintStyle: TypographySystem.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant.withOpacity(0.6),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
            borderSide: BorderSide(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
            borderSide: BorderSide(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: GoldenRatio.spacing16,
            vertical: GoldenRatio.spacing16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProviderRiverpod);
    
    // Load categories if they haven't been loaded yet
    if (productState.categories.isEmpty && !productState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(productProviderRiverpod.notifier).loadCategories('restaurant');
      });
    }
    
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildModernAppBar(context),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(GoldenRatio.spacing16),
                  children: [
                    // Header Section
                    Container(
                      margin: EdgeInsets.only(bottom: GoldenRatio.spacing24),
                      padding: EdgeInsets.all(GoldenRatio.spacing20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.7),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(GoldenRatio.spacing16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: GoldenRatio.spacing12,
                            offset: Offset(0, GoldenRatio.spacing4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: GoldenRatio.xl,
                            height: GoldenRatio.xl,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary.withOpacity(0.8),
                                  AppColors.primaryDark,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: GoldenRatio.spacing16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Product Information',
                                  style: TypographySystem.titleMedium.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: GoldenRatio.spacing4),
                                Text(
                                  'Update your product details and settings',
                                  style: TypographySystem.bodyMedium.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Product Images Section
                    Container(
                      margin: EdgeInsets.only(bottom: GoldenRatio.spacing24),
                      padding: EdgeInsets.all(GoldenRatio.spacing16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius:
                            BorderRadius.circular(GoldenRatio.spacing12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Images',
                            style: TypographySystem.titleMedium.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: GoldenRatio.spacing16),
                          ImagePickerWidget(
                            selectedImage: _selectedImage,
                            isUploading: _isUploading,
                            onPickImage: _pickImage,
                            onRemoveImage: _removeImage,
                          ),
                        ],
                      ),
                    ),

                    // Product Name
                    _buildModernTextField(
                      controller: _nameController,
                      labelText: 'Product Name',
                      hintText: 'Enter product name',
                      prefixIcon: Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.primary,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product name';
                        }
                        return null;
                      },
                    ),

                    // Description
                    _buildModernTextField(
                      controller: _descriptionController,
                      labelText: 'Description',
                      hintText: 'Enter product description',
                      maxLines: 3,
                      prefixIcon: Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product description';
                        }
                        return null;
                      },
                    ),

                    // Category Dropdown
                    Container(
                      margin: EdgeInsets.only(bottom: GoldenRatio.spacing16),
                      child: DropdownButtonFormField<String>(
                        value: () {
                          // Ensure the selected value exists in the available categories
                          final Map<String, ProductCategory> uniqueCategories =
                              {};
                          for (final category in productState.categories) {
                            uniqueCategories[category.id] = category;
                          }

                          // Only return the selected category if it exists in the available categories
                          if (_selectedCategoryId != null &&
                              uniqueCategories
                                  .containsKey(_selectedCategoryId)) {
                            return _selectedCategoryId;
                          }

                          // If categories are loaded but selected category doesn't exist, return null
                          if (uniqueCategories.isNotEmpty) {
                            return null;
                          }

                          // If no categories loaded yet, return null
                          return null;
                        }(),
                        style: TypographySystem.bodyLarge.copyWith(
                          color: AppColors.onSurface,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(
                            Icons.category_outlined,
                            color: AppColors.primary,
                          ),
                          labelStyle: TypographySystem.bodyMedium.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(GoldenRatio.spacing12),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(GoldenRatio.spacing12),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(GoldenRatio.spacing12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: GoldenRatio.spacing16,
                            vertical: GoldenRatio.spacing16,
                          ),
                        ),
                        items: () {
                          // Remove duplicate categories based on ID
                          final Map<String, ProductCategory> uniqueCategories =
                              {};
                          for (final category in productState.categories) {
                            uniqueCategories[category.id] = category;
                          }
                          return uniqueCategories.values.map((category) {
                            return DropdownMenuItem<String>(
                              value: category.id,
                              child: Text(category.name),
                            );
                          }).toList();
                        }(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                    ),

                    // Price
                    _buildModernTextField(
                      controller: _priceController,
                      labelText: 'Price',
                      hintText: 'Enter price',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: AppColors.primary,
                      ),
                      prefixText: '\$',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter price';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),

                    // Availability Toggle
                    Container(
                      margin: EdgeInsets.only(bottom: GoldenRatio.spacing24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius:
                            BorderRadius.circular(GoldenRatio.spacing12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Product Available',
                          style: TypographySystem.bodyLarge.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _isAvailable
                              ? 'Product is visible to customers'
                              : 'Product is hidden from customers',
                          style: TypographySystem.bodyMedium.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        value: _isAvailable,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() {
                            _isAvailable = value;
                          });
                        },
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: GoldenRatio.spacing16,
                          vertical: GoldenRatio.spacing8,
                        ),
                      ),
                    ),

                    // Update Product Button
                    Container(
                      width: double.infinity,
                      height: GoldenRatio.xxl,
                      decoration: BoxDecoration(
                        gradient: _isLoading
                            ? LinearGradient(
                                colors: [
                                  AppColors.onSurfaceVariant.withOpacity(0.4),
                                  AppColors.onSurfaceVariant.withOpacity(0.2),
                                ],
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                              ),
                        borderRadius:
                            BorderRadius.circular(GoldenRatio.spacing12),
                        boxShadow: _isLoading
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: GoldenRatio.spacing12,
                                  offset: Offset(0, GoldenRatio.spacing4),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _updateProduct,
                          borderRadius:
                              BorderRadius.circular(GoldenRatio.spacing12),
                          child: Container(
                            alignment: Alignment.center,
                            child: _isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Update Product',
                                    style: TypographySystem.labelLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = widget.product.imageUrls.isNotEmpty
          ? widget.product.imageUrls.first
          : null;
      
      // If new image selected, upload it first
      if (_selectedImage != null) {
        setState(() {
          _isUploading = true;
        });
        
        // Import and use ImageUploadService
        final uploadResult =
            await ImageUploadService.uploadProductImage(_selectedImage!);

        setState(() {
          _isUploading = false;
        });

        if (uploadResult['success']) {
          imageUrl = uploadResult['imageUrl'];
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Image upload failed: ${uploadResult['message']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Update product with new data
      final result = await ProductService.updateProduct(
        productId: widget.product.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        categoryId: _selectedCategoryId!,
        imageUrl: imageUrl,
        isAvailable: _isAvailable,
      );

      if (result['success'] && mounted) {
        // Refresh products list
        await ref.read(productProviderRiverpod.notifier).loadProducts();

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to update product: ${result['message'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.spacing16),
        ),
        title: Row(
          children: [
            Container(
              width: GoldenRatio.lg,
              height: GoldenRatio.lg,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
            SizedBox(width: GoldenRatio.spacing12),
            Text(
              'Delete Product',
              style: TypographySystem.titleMedium.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this product? This action cannot be undone.',
          style: TypographySystem.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.onSurfaceVariant,
              padding: EdgeInsets.symmetric(
                horizontal: GoldenRatio.spacing16,
                vertical: GoldenRatio.spacing8,
              ),
            ),
            child: Text(
              'Cancel',
              style: TypographySystem.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red, Colors.red.shade700],
              ),
              borderRadius: BorderRadius.circular(GoldenRatio.spacing8),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: GoldenRatio.spacing16,
                  vertical: GoldenRatio.spacing8,
                ),
              ),
              child: Text(
                'Delete',
                style: TypographySystem.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref
          .read(productProviderRiverpod.notifier)
          .deleteProduct(widget.product.id);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        final errorMessage = ref.read(productProviderRiverpod).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to delete product: ${errorMessage ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
}
