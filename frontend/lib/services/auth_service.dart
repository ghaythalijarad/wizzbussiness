import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Provides authentication related services such as login, logout, and password reset.
class AuthService {
  static const String baseUrl =
      'http://localhost:8001'; // Updated to use localhost for iOS simulator

  static String _parseError(dynamic detail) {
    if (detail is String) {
      return detail;
    }
    if (detail is List && detail.isNotEmpty) {
      final firstError = detail[0];
      if (firstError is Map && firstError.containsKey('msg')) {
        return firstError['msg'];
      }
      return jsonEncode(detail);
    }
    if (detail != null) {
      return detail.toString();
    }
    return 'An unknown error occurred';
  }

  /// Store access token in shared preferences
  static Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  /// Get stored access token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Clear stored token
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  /// Login with email and password
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      // TEMPORARY: Use test authentication endpoint while database is unavailable
      // TODO: Switch back to '/auth/jwt/login' once database connectivity is fixed
      final response = await http.post(
        Uri.parse('$baseUrl/test-auth/login'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': email, // FastAPI Users expects 'username' field for email
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'];

        // Store the token for future requests
        await _storeToken(accessToken);

        // Check if we're in test mode
        final isTestMode = data['test_mode'] == true;
        final successMessage = isTestMode
            ? 'Login successful (Test Mode - Database Offline)'
            : 'Login successful';

        return {
          'success': true,
          'message': successMessage,
          'access_token': accessToken,
          'token_type': data['token_type'],
          'test_mode': isTestMode,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': _parseError(errorData['detail']),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get current user profile
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No access token found',
        };
      }

      // Check if we're in test mode by trying to decode the token
      bool isTestMode = false;
      try {
        // Simple check for test token (contains test-user-id)
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          // Add padding if needed for base64 decoding
          final normalizedPayload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
          final decoded = utf8.decode(base64Decode(normalizedPayload));
          isTestMode = decoded.contains('test-user-id');
        }
      } catch (e) {
        // If token decode fails, assume not test mode
      }

      // Choose endpoint based on test mode
      final endpoint = isTestMode ? '$baseUrl/test-auth/me' : '$baseUrl/users/me';

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        return {
          'success': true,
          'user': userData,
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': _parseError(errorData['detail']),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Logout user
  static Future<Map<String, dynamic>> logout() async {
    try {
      await clearToken();
      return {
        'success': true,
        'message': 'Logged out successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error during logout: ${e.toString()}',
      };
    }
  }

  /// Sends a password reset email to the given [email].
  static Future<Map<String, dynamic>> sendPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Password reset email sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send password reset email',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Register a new user account
  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> userData,
    File? licenseFile,
    File? identityFile,
    File? healthCertificateFile,
    File? ownerPhotoFile,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/register-multipart'),
      );

      // Add user data as fields
      userData.forEach((key, value) {
        if (value is Map) {
          request.fields[key] = jsonEncode(value);
        } else {
          request.fields[key] = value.toString();
        }
      });

      // Add files
      if (licenseFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'license_file',
          licenseFile.path,
        ));
      }
      if (identityFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'identity_file',
          identityFile.path,
        ));
      }
      if (healthCertificateFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'health_certificate_file',
          healthCertificateFile.path,
        ));
      }
      if (ownerPhotoFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'owner_photo_file',
          ownerPhotoFile.path,
        ));
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        // Registration successful - backend returns user object
        final userData = jsonDecode(responseBody);
        return {
          'success': true,
          'message': 'Registration successful',
          'user': userData,
        };
      } else {
        // Handle error responses
        String errorMessage = 'Registration failed';

        try {
          final errorData = jsonDecode(responseBody);

          // Handle FastAPI validation errors (422)
          if (response.statusCode == 422 && errorData.containsKey('detail')) {
            if (errorData['detail'] is List) {
              // FastAPI validation error format
              final errors = errorData['detail'] as List;
              if (errors.isNotEmpty && errors[0] is Map) {
                final firstError = errors[0] as Map;
                errorMessage = firstError['msg'] ?? 'Validation error';
              }
            } else {
              errorMessage = errorData['detail'].toString();
            }
          }
          // Handle custom HTTP exceptions (400, 500, etc.)
          else if (errorData.containsKey('detail')) {
            final detail = errorData['detail'];
            if (detail == 'REGISTER_USER_ALREADY_EXISTS') {
              errorMessage = 'A user with this email already exists';
            } else {
              errorMessage = detail.toString();
            }
          }
          // Handle other error formats
          else {
            errorMessage = _parseError(errorData['detail'] ?? errorData);
          }
        } catch (parseError) {
          // If JSON parsing fails, use a generic message
          errorMessage = 'Registration failed (Status: ${response.statusCode})';
        }

        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Reset password using token and new password
  static Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Password reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to reset password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Change password for current user
  static Future<Map<String, dynamic>> changePassword(
      String oldPassword, String newPassword) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No access token found',
        };
      }
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Password changed successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': _parseError(errorData['detail']),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Request an OTP for password reset via email or phone
  static Future<Map<String, dynamic>> requestOtp(
    String contact,
    String method, // 'email' or 'phone'
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/otp/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contact': contact, 'method': method}),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'OTP sent successfully'};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': _parseError(errorData['detail'])};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Reset password using OTP code
  static Future<Map<String, dynamic>> resetPasswordWithOtp(
    String contact,
    String method,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact': contact,
          'method': method,
          'code': code,
          'new_password': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password reset successfully'};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': _parseError(errorData['detail'])};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
