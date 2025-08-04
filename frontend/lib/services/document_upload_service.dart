import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';

class DocumentUploadService {
  static String get baseUrl => AppConfig.baseUrl;
  static const uuid = Uuid();

  /// Upload business license document and return the URL
  static Future<Map<String, dynamic>> uploadBusinessLicense(
      File documentFile) async {
    return _uploadDocument(documentFile, 'business-license');
  }

  /// Upload owner identity document and return the URL
  static Future<Map<String, dynamic>> uploadOwnerIdentity(
      File documentFile) async {
    return _uploadDocument(documentFile, 'owner-identity');
  }

  /// Upload health certificate document and return the URL
  static Future<Map<String, dynamic>> uploadHealthCertificate(
      File documentFile) async {
    return _uploadDocument(documentFile, 'health-certificate');
  }

  /// Upload owner photo and return the URL
  static Future<Map<String, dynamic>> uploadOwnerPhoto(
      File documentFile) async {
    return _uploadDocument(documentFile, 'owner-photo');
  }

  /// Private method to handle document uploads
  static Future<Map<String, dynamic>> _uploadDocument(
      File documentFile, String documentType) async {
    try {
      // Read document file as bytes
      final documentBytes = await documentFile.readAsBytes();

      // Determine file extension and MIME type
      final originalPath = documentFile.path.toLowerCase();
      String fileExtension = 'jpg';
      String mimeType = 'image/jpeg';

      if (originalPath.endsWith('.png')) {
        fileExtension = 'png';
        mimeType = 'image/png';
      } else if (originalPath.endsWith('.pdf')) {
        fileExtension = 'pdf';
        mimeType = 'application/pdf';
      } else if (originalPath.endsWith('.jpg') ||
          originalPath.endsWith('.jpeg')) {
        fileExtension = 'jpg';
        mimeType = 'image/jpeg';
      }

      final fileName = '${documentType}_${uuid.v4()}.$fileExtension';

      // Create multipart request to document upload endpoint
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/$documentType'),
      );

      // Add file to request with proper MIME type
      request.files.add(
        http.MultipartFile.fromBytes(
          'image', // Use 'image' field name for consistency with backend
          documentBytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Add document type header
      request.headers['x-upload-type'] = documentType;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Document upload response status: ${response.statusCode}');
      print('Document upload response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return {
            'success': true,
            'imageUrl': responseData['imageUrl'],
            'message': responseData['message'] ??
                '${_getDocumentDisplayName(documentType)} uploaded successfully',
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
      print('Error uploading $documentType: $e');
      return {
        'success': false,
        'message':
            'Error uploading ${_getDocumentDisplayName(documentType)}: $e',
      };
    }
  }

  /// Get display name for document type
  static String _getDocumentDisplayName(String documentType) {
    switch (documentType) {
      case 'business-license':
        return 'Business License';
      case 'owner-identity':
        return 'Owner Identity';
      case 'health-certificate':
        return 'Health Certificate';
      case 'owner-photo':
        return 'Owner Photo';
      default:
        return 'Document';
    }
  }
}
