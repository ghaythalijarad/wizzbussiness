import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// Provides an instance of [ApiService] to the app.
///
/// This allows other providers and widgets to access the [ApiService]
/// to make backend API calls.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
