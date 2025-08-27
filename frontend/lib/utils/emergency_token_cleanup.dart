import 'package:shared_preferences/shared_preferences.dart';

/// Emergency cleanup utility to completely clear corrupted tokens and reset authentication
class EmergencyTokenCleanup {
  static const List<String> _allTokenKeys = [
    'access_token',
    'refresh_token', 
    'id_token',
    'access_token_key',
    'refresh_token_key',
    'id_token_key',
    'auth_token',
    'bearer_token',
    'jwt_token',
    'user_token',
    'session_token',
    'api_token',
    'authorization_token',
  ];

  /// Emergency cleanup - removes all possible token storage locations
  static Future<void> emergencyCleanup() async {
    print('🚨 [EMERGENCY] Starting comprehensive token cleanup...');
    
    final prefs = await SharedPreferences.getInstance();
    
    // Get all keys in storage
    final allKeys = prefs.getKeys();
    print('📋 Found ${allKeys.length} keys in SharedPreferences');
    
    int removedCount = 0;
    
    // Remove all known token key patterns
    for (final key in _allTokenKeys) {
      if (prefs.containsKey(key)) {
        await prefs.remove(key);
        removedCount++;
        print('🗑️ Removed: $key');
      }
    }
    
    // Remove any key that might contain token data (broader search)
    for (final key in allKeys) {
      final lowerKey = key.toLowerCase();
      if (lowerKey.contains('token') || 
          lowerKey.contains('auth') || 
          lowerKey.contains('bearer') ||
          lowerKey.contains('jwt') ||
          lowerKey.contains('session')) {
        await prefs.remove(key);
        removedCount++;
        print('🗑️ Removed suspicious key: $key');
      }
    }
    
    // Clear any other authentication-related data
    final authRelatedKeys = [
      'user_id',
      'business_id', 
      'cognito_user_id',
      'user_email',
      'last_login',
      'auth_state',
      'login_state',
      'user_session',
      'authenticated',
      'is_logged_in',
    ];
    
    for (final key in authRelatedKeys) {
      if (prefs.containsKey(key)) {
        await prefs.remove(key);
        removedCount++;
        print('🗑️ Removed auth data: $key');
      }
    }
    
    print('✅ Emergency cleanup complete! Removed $removedCount items');
    print('🔄 App should now require fresh login');
  }

  /// Validate current token storage state
  static Future<void> validateTokenState() async {
    print('🔍 [VALIDATION] Checking current token state...');
    
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    
    bool foundCorruptedData = false;
    
    for (final key in allKeys) {
      final value = prefs.get(key);
      if (value is String) {
        // Check for corruption indicators
        final hasNewlines = value.contains('\n') || value.contains('\r');
        final hasCyrillic = RegExp(r'[\u0400-\u04FF]').hasMatch(value);
        final hasEquals = value.startsWith('=') || value.contains('|=');
        final hasPipeChar = value.contains('|');
        
        if (hasNewlines || hasCyrillic || hasEquals || hasPipeChar) {
          print('🚨 CORRUPTED DATA FOUND:');
          print('   Key: $key');
          print('   Length: ${value.length}');
          print('   Has newlines: $hasNewlines');
          print('   Has Cyrillic: $hasCyrillic');
          print('   Has equals prefix: $hasEquals');
          print('   Has pipe chars: $hasPipeChar');
          print('   Preview: ${value.substring(0, value.length > 50 ? 50 : value.length)}...');
          foundCorruptedData = true;
        }
      }
    }
    
    if (!foundCorruptedData) {
      print('✅ No corrupted token data found');
    }
  }

  /// Force regenerate all tokens by clearing everything
  static Future<void> forceTokenRegeneration() async {
    print('💥 [FORCE] Clearing ALL authentication data for fresh start...');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Nuclear option - clear everything
    
    print('✅ All SharedPreferences cleared');
    print('🔄 User will need to login again');
  }
}
