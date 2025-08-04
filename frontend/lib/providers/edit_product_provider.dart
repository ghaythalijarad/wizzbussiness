import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/image_upload_service.dart';
import 'product_provider.dart';

enum EditProductStateStatus { initial, loading, success, error }

class EditProductState {
  final EditProductStateStatus status;
  final String? errorMessage;

  EditProductState({this.status = EditProductStateStatus.initial, this.errorMessage});
}

class EditProductNotifier extends StateNotifier<EditProductState> {
  EditProductNotifier(this.ref, this.productId) : super(EditProductState());

  final Ref ref;
  final String productId;

  Future<void> updateProduct({
    required String name,
    required String description,
    required double price,
    required String categoryId,
    required bool isAvailable,
    File? imageFile,
    String? imageUrl,
  }) async {
    state = EditProductState(status: EditProductStateStatus.loading);
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

      final result = await ProductService.updateProduct(
        productId: productId,
        name: name,
        description: description,
        price: price,
        categoryId: categoryId,
        isAvailable: isAvailable,
        imageUrl: finalImageUrl,
      );

      if (result['success']) {
        ref.invalidate(productsProvider);
        state = EditProductState(status: EditProductStateStatus.success);
      } else {
        state = EditProductState(
          status: EditProductStateStatus.error,
          errorMessage: result['message'] ?? 'Failed to update product',
        );
      }
    } catch (e) {
      state = EditProductState(status: EditProductStateStatus.error, errorMessage: e.toString());
    }
  }
}

final editProductProvider = StateNotifierProvider.autoDispose.family<EditProductNotifier, EditProductState, String>(
  (ref, productId) => EditProductNotifier(ref, productId),
);
