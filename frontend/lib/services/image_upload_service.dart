import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import 'app_auth_service.dart';

class ImageUploadService {
  static String get baseUrl => AppConfig.baseUrl;
  static const uuid = Uuid();

  /// Upload image file and return the URL
  static Future<Map<String, dynamic>> uploadProductImage(File imageFile) async {
    try {
      final token = await AppAuthService.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No access token found',
        };
      }

      // Read image file as bytes
      final imageBytes = await imageFile.readAsBytes();
      final fileName = '${uuid.v4()}.jpg';
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/product-image'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add file to request
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'imageUrl': data['imageUrl'],
          'message': 'Image uploaded successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to upload image',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Upload image from bytes (for web compatibility)
  static Future<Map<String, dynamic>> uploadProductImageFromBytes({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final token = await AppAuthService.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No access token found',
        };
      }

      final uniqueFileName = '${uuid.v4()}_$fileName';
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/product-image'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add file to request
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: uniqueFileName,
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'imageUrl': data['imageUrl'],
          'message': 'Image uploaded successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to upload image',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Delete uploaded image
  static Future<Map<String, dynamic>> deleteProductImage(String imageUrl) async {
    try {
      final token = await AppAuthService.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No access token found',
        };
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/upload/product-image'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'imageUrl': imageUrl}),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Image deleted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete image',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
