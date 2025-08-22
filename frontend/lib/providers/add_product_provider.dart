import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/product_service.dart';
import '../services/image_upload_service.dart';
import 'product_provider.dart';

enum AddProductStateStatus { initial, loading, success, error }

class AddProductState {
  final AddProductStateStatus status;
  final String? errorMessage;

  AddProductState({this.status = AddProductStateStatus.initial, this.errorMessage});
}

class AddProductNotifier extends StateNotifier<AddProductState> {
  AddProductNotifier(this.ref) : super(AddProductState());

  final Ref ref;

  Future<void> createProduct({
    required String name,
    required String description,
    required double price,
    required String categoryId,
    required bool isAvailable,
    File? imageFile,
    String? imageUrl,
  }) async {
    state = AddProductState(status: AddProductStateStatus.loading);
    try {
      String? finalImageUrl = imageUrl;
      if (imageFile != null) {
        final uploadResult = await ImageUploadService.uploadProductImage(imageFile);
        if (uploadResult['success']) {
          finalImageUrl = uploadResult['imageUrl'];
        } else {
          throw Exception(uploadResult['message'] ?? 'Image upload failed');
        }
      }

      final result = await ProductService.createProduct(
        name: name,
        description: description,
        price: price,
        categoryId: categoryId,
        isAvailable: isAvailable,
        imageUrl: finalImageUrl,
      );

      if (result['success']) {
        ref.invalidate(productsProvider);
        state = AddProductState(status: AddProductStateStatus.success);
      } else {
        print(
            '❌ Failed to create product. Backend message: ${result['message']}');
        state = AddProductState(
          status: AddProductStateStatus.error,
          errorMessage: result['message'] ?? 'Failed to create product',
        );
      }
    } catch (e) {
      print('❌ Exception when creating product: $e');
      state = AddProductState(status: AddProductStateStatus.error, errorMessage: e.toString());
    }
  }
}

final addProductProvider = StateNotifierProvider.autoDispose<AddProductNotifier, AddProductState>(
  (ref) => AddProductNotifier(ref),
);
