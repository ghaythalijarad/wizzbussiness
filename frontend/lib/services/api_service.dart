import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'package:hadhir_business/config/app_config.dart';
import 'app_auth_service.dart';
import 'auth_header_builder.dart';
import '../utils/token_manager.dart';

class ApiService {
  final String baseUrl = AppConfig.baseUrl;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Store tokens and user data in shared preferences using TokenManager
      final prefs = await SharedPreferences.getInstance();
      
      // Use TokenManager to sanitize and store access token
      if (data['access_token'] != null && data['access_token'].toString().isNotEmpty) {
        await TokenManager.setAccessToken(data['access_token'].toString());
      }
      
      // Store refresh token (also sanitize it)
      if (data['refresh_token'] != null && data['refresh_token'].toString().isNotEmpty) {
        await prefs.setString('refresh_token', data['refresh_token'].toString().trim());
      }
      
      await prefs.setString('user', jsonEncode(data['user']));
      return data;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<User> getMerchantDetails() async {
    try {
      // Use AppAuthService to get current user data
      final userMap = await AppAuthService.getCurrentUser();

      if (userMap != null && userMap['userId'] != null) {
        // Create a User object from the data returned by AppAuthService
        // Ensure email_verified is properly converted to boolean
        bool emailVerified = false;
        final emailVerifiedValue = userMap['email_verified'];
        if (emailVerifiedValue is bool) {
          emailVerified = emailVerifiedValue;
        } else if (emailVerifiedValue is String) {
          emailVerified = emailVerifiedValue.toLowerCase() == 'true';
        }

        final user = User(
          id: userMap['userId'],
          email: userMap['email'] ?? '',
          firstName: userMap['firstName'] ?? '',
          lastName: userMap['lastName'] ?? '',
          phoneNumber: userMap['phoneNumber'],
          profileImageUrl: userMap['profileImageUrl'],
          emailVerified: emailVerified,
          createdAt:
              DateTime.tryParse(userMap['createdAt'] ?? '') ?? DateTime.now(),
          updatedAt:
              DateTime.tryParse(userMap['updatedAt'] ?? '') ?? DateTime.now(),
        );
        return user;
      } else {
        throw Exception('No user data found in AppAuthService');
      }
    } catch (e) {
      // Fallback to SharedPreferences if AppAuthService fails
      final prefs = await SharedPreferences.getInstance();
      final String? userString = prefs.getString('user');

      if (userString != null) {
        final user = User.fromJson(jsonDecode(userString));
        return user;
      } else {
        throw Exception(
            'Failed to load user details from both AppAuthService and SharedPreferences: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getUserBusinesses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/auth/user-businesses'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['businesses'] ?? []);
      } else {
        throw Exception('Failed to get user businesses: ${data['message']}');
      }
    } else {
      throw Exception('Failed to get user businesses: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getDiscounts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/discounts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['discounts'] ?? []);
      } else {
        throw Exception('Failed to get discounts: ${data['message']}');
      }
    } else {
      throw Exception('Failed to get discounts: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> registerSimple({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> registerBusiness(
      Map<String, dynamic> businessData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register-with-business'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(businessData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to register business: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to sign in: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> registerWithBusiness({
    required String email,
    required String password,
    required Map<String, dynamic> businessData,
  }) async {
    print('🔄 ApiService.registerWithBusiness called');
    print('📧 Email: $email');
    print('🏢 Business data: $businessData');
    
    // Combine user data with business data for the request
    final requestData = {
      'email': email,
      'password': password,
      ...businessData,
    };
    
    print('📦 Full request data: ${requestData.keys.toList()}');
    print('🌐 Making HTTP POST to: $baseUrl/auth/register-with-business');

    final response = await http.post(
      Uri.parse('$baseUrl/auth/register-with-business'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestData),
    );

    print('📡 HTTP Response status: ${response.statusCode}');
    print('📡 HTTP Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Registration API call successful: $data');
      return data;
    } else {
      print('❌ Registration API call failed: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to register with business: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> confirmRegistration({
    required String email,
    required String confirmationCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'verificationCode': confirmationCode,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to confirm registration: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> resendRegistrationCode({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to resend registration code: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> checkEmailExists({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/check-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to check email: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUserByEmail({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/get-user-by-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to get user by email: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createDiscount(
      Map<String, dynamic> discountData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/discounts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(discountData),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['discount'];
      } else {
        throw Exception('Failed to create discount: ${data['message']}');
      }
    } else {
      throw Exception('Failed to create discount: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateDiscount(
      String discountId, Map<String, dynamic> discountData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/discounts/$discountId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(discountData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['discount'];
      } else {
        throw Exception('Failed to update discount: ${data['message']}');
      }
    } else {
      throw Exception('Failed to update discount: ${response.body}');
    }
  }

  Future<void> deleteDiscount(String discountId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/discounts/$discountId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(
          'Failed to delete discount: ${data['message'] ?? response.body}');
    }
  }

  // POS Settings API Methods

  /// Update POS settings for a business
  Future<Map<String, dynamic>> updatePosSettings(
      String businessId, Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/businesses/$businessId/pos-settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(settings),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
          'Failed to update POS settings: ${data['message'] ?? response.body}');
    }
  }

  /// Test POS connection with the provided configuration
  Future<Map<String, dynamic>> testPosConnection(
      String businessId, Map<String, dynamic> testConfig) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/businesses/$businessId/pos-settings/test-connection'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(testConfig),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
          'Failed to test POS connection: ${data['message'] ?? response.body}');
    }
  }

  /// Get POS sync logs for a business
  Future<List<dynamic>> getPosSyncLogs(String businessId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/businesses/$businessId/pos-settings/sync-logs'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['logs'] ?? [];
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
          'Failed to get POS sync logs: ${data['message'] ?? response.body}');
    }
  }

  /// Get POS settings for a business
  Future<Map<String, dynamic>> getPosSettings(String businessId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/businesses/$businessId/pos-settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
          'Failed to get POS settings: ${data['message'] ?? response.body}');
    }
  }

  /// Update business location settings
  Future<Map<String, dynamic>> updateBusinessLocationSettings(
      String businessId, Map<String, dynamic> locationSettings) async {
    final headers = await AuthHeaderBuilder.build();

    final response = await http.put(
      Uri.parse('$baseUrl/businesses/$businessId/location-settings'),
      headers: headers,
      body: jsonEncode(locationSettings),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
          'Failed to update business location settings: ${data['message'] ?? response.body}');
    }
  }

  /// Get business location settings
  Future<Map<String, dynamic>> getBusinessLocationSettings(
      String businessId) async {
    final headers = await AuthHeaderBuilder.build();

    final response = await http.get(
      Uri.parse('$baseUrl/businesses/$businessId/location-settings'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
          'Failed to get business location settings: ${data['message'] ?? response.body}');
    }
  }

  /// Get business working hours
  Future<Map<String, dynamic>> getBusinessWorkingHours(
      String businessId) async {
    final headers = await AuthHeaderBuilder.build();

    final response = await http.get(
      Uri.parse('$baseUrl/businesses/$businessId/working-hours'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
          'Failed to get business working hours: ${data['message'] ?? response.body}');
    }
  }

  /// Update business working hours
  Future<Map<String, dynamic>> updateBusinessWorkingHours(
      String businessId, Map<String, dynamic> workingHours) async {
    final headers = await AuthHeaderBuilder.build();

    final response = await http.put(
      Uri.parse('$baseUrl/businesses/$businessId/working-hours'),
      headers: headers,
      body: jsonEncode(workingHours),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
          'Failed to update business working hours: ${data['message'] ?? response.body}');
    }
  }

  /// Register device FCM/APNs token with backend
  Future<void> registerDeviceToken(String deviceToken) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      throw Exception('No access token found');
    }
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/register-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'deviceToken': deviceToken}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to register device token: ${response.body}');
    }
  }

  /// Update business online/offline status
  Future<void> updateBusinessOnlineStatus(
      String businessId, String userId, bool isOnline) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/businesses/$businessId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'status': isOnline ? 'ONLINE' : 'OFFLINE',
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(
          'Failed to update business status: ${errorData['error'] ?? response.body}');
    }
  }

  /// Get business online status
  Future<Map<String, dynamic>> getBusinessOnlineStatus(
      String businessId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/businesses/$businessId/online-status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          'Failed to get business status: ${errorData['error'] ?? response.body}');
    }
  }

  // Business Profile Management Methods

  /// Get business profile information
  Future<Map<String, dynamic>> getBusinessProfile(String businessId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/businesses/$businessId/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          'Failed to get business profile: ${errorData['message'] ?? response.body}');
    }
  }

  /// Get complete business details including all fields from DynamoDB
  Future<Map<String, dynamic>> getBusinessDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/business/details'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          'Failed to get business details: ${errorData['message'] ?? response.body}');
    }
  }

  /// Update business profile information
  Future<Map<String, dynamic>> updateBusinessProfile(
      String businessId, Map<String, dynamic> profileData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/businesses/$businessId/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(profileData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          'Failed to update business profile: ${errorData['message'] ?? response.body}');
    }
  }

  /// Update business photo
  Future<Map<String, dynamic>> updateBusinessPhoto(
      String businessId, String photoUrl) async {
    return await updateBusinessProfile(businessId, {
      'businessPhotoUrl': photoUrl,
    });
  }

  /// Update business basic information
  Future<Map<String, dynamic>> updateBusinessBasicInfo(
    String businessId, {
    String? businessName,
    String? ownerName,
    String? description,
    String? website,
    String? phoneNumber,
  }) async {
    final updateData = <String, dynamic>{};

    if (businessName != null) updateData['businessName'] = businessName;
    if (ownerName != null) updateData['ownerName'] = ownerName;
    if (description != null) updateData['description'] = description;
    if (website != null) updateData['website'] = website;
    if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;

    return await updateBusinessProfile(businessId, updateData);
  }

  /// Update business address information
  Future<Map<String, dynamic>> updateBusinessAddress(
    String businessId, {
    String? address,
    String? city,
    String? district,
    String? country,
    String? street,
    double? latitude,
    double? longitude,
  }) async {
    final updateData = <String, dynamic>{};

    if (address != null) updateData['address'] = address;
    if (city != null) updateData['city'] = city;
    if (district != null) updateData['district'] = district;
    if (country != null) updateData['country'] = country;
    if (street != null) updateData['street'] = street;
    if (latitude != null) updateData['latitude'] = latitude;
    if (longitude != null) updateData['longitude'] = longitude;

    return await updateBusinessProfile(businessId, updateData);
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Get access token for authentication
    final accessToken = await AppAuthService.getAccessToken();

    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to change password: ${response.body}');
    }
  }

  /// Create virtual WebSocket connection for tracking business user login
  Future<Map<String, dynamic>> createVirtualWebSocketConnection(
      Map<String, dynamic> connectionData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/websocket/virtual-connection'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(connectionData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception(
          'Failed to create virtual WebSocket connection: ${response.body}');
    }
  }

  /// Remove business WebSocket connections on logout
  Future<Map<String, dynamic>> removeBusinessWebSocketConnections(
      Map<String, dynamic> removalData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/websocket/business-connections'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(removalData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception(
          'Failed to remove WebSocket connections: ${response.body}');
    }
  }

  /// Track business user login in WebSocket connections table (lightweight)
  Future<Map<String, dynamic>> trackBusinessLogin({
    required String businessId,
    required String userId,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/track-login'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'businessId': businessId,
        'userId': userId,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to track business login: ${response.body}');
    }
  }

  /// Remove business user login tracking from WebSocket connections table
  Future<Map<String, dynamic>> trackBusinessLogout({
    required String businessId,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/track-logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'businessId': businessId,
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to track business logout: ${response.body}');
    }
  }
}
