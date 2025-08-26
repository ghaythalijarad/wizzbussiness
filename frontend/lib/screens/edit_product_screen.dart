import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/product.dart';
import '../providers/edit_product_provider.dart';
import '../providers/product_provider.dart';
import '../services/product_service.dart';
import '../services/image_upload_service.dart';
import '../widgets/wizz_business_button.dart';
import '../widgets/wizz_business_text_form_field.dart';
import '../widgets/image_picker_widget.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final Product product;

  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategoryId;
  bool _isAvailable = true;
  File? _selectedImage;
  String? _initialImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _nameController.text = widget.product.name;
    _descriptionController.text = widget.product.description;
    _priceController.text = widget.product.price.toStringAsFixed(2);
    _imageUrlController.text = widget.product.imageUrl ?? '';
    _initialImageUrl = widget.product.imageUrl;
    _selectedCategoryId = widget.product.categoryId;
    _isAvailable = widget.product.isAvailable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? finalImageUrl = _imageUrlController.text.trim();
    if (finalImageUrl.isEmpty) {
      finalImageUrl = null;
    }

    await ref.read(editProductProvider(widget.product.id).notifier).updateProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          categoryId: _selectedCategoryId!,
          isAvailable: _isAvailable,
          imageFile: _selectedImage,
          imageUrl: _selectedImage == null ? finalImageUrl : null,
        );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Product name is required';
    }
    if (value.trim().length < 2) {
      return 'Product name must be at least 2 characters';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Product description is required';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }

    final price = double.tryParse(value.trim());
    if (price == null) {
      return 'Please enter a valid price';
    }

    if (price <= 0) {
      return 'Price must be greater than 0';
    }

    if (price > 9999.99) {
      return 'Price cannot exceed \$9999.99';
    }

    return null;
  }

  String? _validateImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Image URL is optional
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  // Image compression settings optimized for quality vs file size:
  // - maxWidth/maxHeight: 1920px (up from 1024px) for better detail
  // - imageQuality: 95% (up from 80%) for less compression
  // - Typical result: 500KB-2MB files with much better quality
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 95,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageUrlController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 95,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageUrlController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageUrlController.clear();
      _initialImageUrl = null; // To reflect that the original image is gone
    });
  }

  bool _hasChanges() {
    final price = double.tryParse(_priceController.text.trim());
    final currentImageUrl =
        _selectedImage != null ? '' : _imageUrlController.text.trim();
    final originalImageUrl = widget.product.imageUrl ?? '';

    return _nameController.text.trim() != widget.product.name ||
        _descriptionController.text.trim() != widget.product.description ||
        (price != null && price != widget.product.price) ||
        _selectedCategoryId != widget.product.categoryId ||
        _selectedImage != null ||
        currentImageUrl != originalImageUrl ||
        _isAvailable != widget.product.isAvailable;
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges()) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
              'You have unsaved changes. Do you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EditProductState>(editProductProvider(widget.product.id),
        (previous, next) {
      if (next.status == EditProductStateStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else if (next.status == EditProductStateStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Failed to update product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final editState = ref.watch(editProductProvider(widget.product.id));
    final isLoading = editState.status == EditProductStateStatus.loading;
    final categoriesAsync = ref.watch(categoriesProvider('restaurant'));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Product'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Name
                WizzBusinessTextFormField(
                  controller: _nameController,
                  labelText: 'Product Name *',
                  prefixIcon: const Icon(Icons.shopping_bag),
                  validator: _validateName,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Description
                WizzBusinessTextFormField(
                  controller: _descriptionController,
                  labelText: 'Description *',
                  prefixIcon: const Icon(Icons.description),
                  validator: _validateDescription,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Price
                WizzBusinessTextFormField(
                  controller: _priceController,
                  labelText: 'Price (\$) *',
                  prefixIcon: const Icon(Icons.attach_money),
                  validator: _validatePrice,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 16),

                // Category Selection
                categoriesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (categories) {
                    final filteredCategories = categories
                        .where((cat) => cat.id.isNotEmpty && cat.name.isNotEmpty)
                        .toList();

                    if (filteredCategories.isEmpty) {
                      return const Text('No categories available.');
                    }

                    final isValidCategory = filteredCategories
                        .any((cat) => cat.id == _selectedCategoryId);
                    if (!isValidCategory && filteredCategories.isNotEmpty) {
                      _selectedCategoryId = filteredCategories.first.id;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.category, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategoryId,
                                hint: const Text('Select Category *'),
                                isExpanded: true,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedCategoryId = newValue;
                                  });
                                },
                                items: filteredCategories.map((category) {
                                  return DropdownMenuItem<String>(
                                    value: category.id,
                                    child: Text(category.name),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Image Section
                ImagePickerWidget(
                  selectedImage: _selectedImage,
                  uploadedImageUrl:
                      _selectedImage == null ? _initialImageUrl : null,
                  isUploading: isLoading,
                  onPickImage: _showImageSourceDialog,
                  onRemoveImage: _removeImage,
                ),
                const SizedBox(height: 16),

                // Manual Image URL (as a fallback)
                if (_selectedImage == null)
                  WizzBusinessTextFormField(
                    controller: _imageUrlController,
                    labelText: 'Or enter Image URL',
                    prefixIcon: const Icon(Icons.link),
                    validator: _validateImageUrl,
                    keyboardType: TextInputType.url,
                  ),
                const SizedBox(height: 24),

                // Availability Toggle
                SwitchListTile(
                  title: const Text('Product is Available'),
                  value: _isAvailable,
                  onChanged: (value) {
                    setState(() {
                      _isAvailable = value;
                    });
                  },
                  secondary: const Icon(Icons.visibility),
                ),
                const SizedBox(height: 32),

                // Update Button
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : WizzBusinessButton(
                        onPressed: _updateProduct,
                        text: 'Update Product',
                      ),
                const SizedBox(height: 16),

                // Cancel Button
                OutlinedButton(
                  onPressed:
                      isLoading ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
