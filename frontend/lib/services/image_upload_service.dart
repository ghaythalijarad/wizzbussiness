import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import 'app_auth_service.dart';

class ImageUploadService {
  static String get baseUrl => AppConfig.baseUrl;
  static const uuid = Uuid();

  /// Upload business photo and return the URL
  static Future<Map<String, dynamic>> uploadBusinessPhoto(
      File imageFile) async {
    try {
      // Use the dedicated business-photo endpoint

      // Read image file as bytes
      final imageBytes = await imageFile.readAsBytes();

      // Determine file extension from original file
      final originalPath = imageFile.path.toLowerCase();
      final fileExtension = originalPath.endsWith('.png') ? 'png' : 'jpg';
      final mimeType = fileExtension == 'png' ? 'image/png' : 'image/jpeg';
      final fileName = 'business_${uuid.v4()}.$fileExtension';

      // Create multipart request to business photo endpoint
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '$baseUrl/upload/business-photo'), // Use dedicated business photo endpoint
      );

      // Add file to request with proper MIME type
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Business photo upload response status: ${response.statusCode}');
      print('Business photo upload response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return {
            'success': true,
            'imageUrl': responseData['imageUrl'],
            'message': responseData['message'] ??
                'Business photo uploaded successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Upload failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Upload failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error uploading business photo: $e');
      return {
        'success': false,
        'message': 'Error uploading business photo: $e',
      };
    }
  }

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

      // Determine file extension from original file
      final originalPath = imageFile.path.toLowerCase();
      final fileExtension = originalPath.endsWith('.png') ? 'png' : 'jpg';
      final mimeType = fileExtension == 'png' ? 'image/png' : 'image/jpeg';
      final fileName = '${uuid.v4()}.$fileExtension';

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/product-image'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add file to request with proper MIME type
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
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

      // Determine file extension from file name
      final fileNameLower = fileName.toLowerCase();
      final fileExtension = fileNameLower.endsWith('.png') ? 'png' : 'jpg';
      final mimeType = fileExtension == 'png' ? 'image/png' : 'image/jpeg';
      final uniqueFileName = '${uuid.v4()}.$fileExtension';

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/product-image'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add file to request with proper MIME type
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: uniqueFileName,
          contentType: MediaType.parse(mimeType),
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
  static Future<Map<String, dynamic>> deleteProductImage(
      String imageUrl) async {
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
