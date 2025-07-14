import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pos_settings.dart';

/// Service for managing Point of Sale (POS) settings and configurations
class PosService {
  static const String _posSettingsKey = 'pos_settings';
  static const String _receiptSettingsKey = 'receipt_settings';
  static const String _printerSettingsKey = 'printer_settings';

  /// Default POS settings
  static const Map<String, dynamic> _defaultPosSettings = {
    'autoAcceptOrders': true,
    'orderNotificationSound': true,
    'displayOrderTimer': true,
    'maxProcessingTimeMinutes': 30,
    'currency': 'USD',
    'taxRate': 0.0,
    'serviceChargeRate': 0.0,
  };

  /// Default receipt settings
  static const Map<String, dynamic> _defaultReceiptSettings = {
    'businessName': '',
    'businessAddress': '',
    'businessPhone': '',
    'showLogo': false,
    'showQrCode': true,
    'footerMessage': 'Thank you for your business!',
    'paperSize': 'A4',
  };

  /// Default printer settings
  static const Map<String, dynamic> _defaultPrinterSettings = {
    'printerEnabled': false,
    'printerName': '',
    'printerIp': '',
    'autoPrintReceipts': false,
    'printKitchenOrders': true,
  };

  /// Get POS settings
  static Future<Map<String, dynamic>> getPosSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_posSettingsKey);
    
    if (settingsJson != null) {
      return {..._defaultPosSettings, ...jsonDecode(settingsJson)};
    }
    
    return Map<String, dynamic>.from(_defaultPosSettings);
  }

  /// Save POS settings
  static Future<bool> savePosSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings);
      return await prefs.setString(_posSettingsKey, settingsJson);
    } catch (e) {
      print('Error saving POS settings: $e');
      return false;
    }
  }

  /// Get receipt settings
  static Future<Map<String, dynamic>> getReceiptSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_receiptSettingsKey);
    
    if (settingsJson != null) {
      return {..._defaultReceiptSettings, ...jsonDecode(settingsJson)};
    }
    
    return Map<String, dynamic>.from(_defaultReceiptSettings);
  }

  /// Save receipt settings
  static Future<bool> saveReceiptSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings);
      return await prefs.setString(_receiptSettingsKey, settingsJson);
    } catch (e) {
      print('Error saving receipt settings: $e');
      return false;
    }
  }

  /// Get printer settings
  static Future<Map<String, dynamic>> getPrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_printerSettingsKey);
    
    if (settingsJson != null) {
      return {..._defaultPrinterSettings, ...jsonDecode(settingsJson)};
    }
    
    return Map<String, dynamic>.from(_defaultPrinterSettings);
  }

  /// Save printer settings
  static Future<bool> savePrinterSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings);
      return await prefs.setString(_printerSettingsKey, settingsJson);
    } catch (e) {
      print('Error saving printer settings: $e');
      return false;
    }
  }

  /// Test printer connection
  static Future<bool> testPrinterConnection(String printerIp) async {
    // TODO: Implement actual printer connection test
    // For now, simulate a test
    await Future.delayed(const Duration(seconds: 2));
    return printerIp.isNotEmpty;
  }

  /// Reset all POS settings to defaults
  static Future<bool> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_posSettingsKey);
      await prefs.remove(_receiptSettingsKey);
      await prefs.remove(_printerSettingsKey);
      return true;
    } catch (e) {
      print('Error resetting POS settings: $e');
      return false;
    }
  }

  /// Get specific setting value
  static Future<T?> getSetting<T>(String category, String key) async {
    Map<String, dynamic> settings;
    
    switch (category) {
      case 'pos':
        settings = await getPosSettings();
        break;
      case 'receipt':
        settings = await getReceiptSettings();
        break;
      case 'printer':
        settings = await getPrinterSettings();
        break;
      default:
        return null;
    }
    
    return settings[key] as T?;
  }

  /// Update specific setting value
  static Future<bool> updateSetting(String category, String key, dynamic value) async {
    Map<String, dynamic> settings;
    
    switch (category) {
      case 'pos':
        settings = await getPosSettings();
        settings[key] = value;
        return await savePosSettings(settings);
      case 'receipt':
        settings = await getReceiptSettings();
        settings[key] = value;
        return await saveReceiptSettings(settings);
      case 'printer':
        settings = await getPrinterSettings();
        settings[key] = value;
        return await savePrinterSettings(settings);
      default:
        return false;
    }
  }

  /// Get display name for POS system type
  static String getSystemTypeName(PosSystemType type) {
    switch (type) {
      case PosSystemType.genericApi:
        return 'Generic API';
      case PosSystemType.square:
        return 'Square';
      case PosSystemType.toast:
        return 'Toast';
      case PosSystemType.clover:
        return 'Clover';
      case PosSystemType.shopify:
        return 'Shopify';
      case PosSystemType.woocommerce:
        return 'WooCommerce';
    }
  }

  /// Validate API endpoint URL
  static bool isValidApiEndpoint(String endpoint) {
    if (endpoint.isEmpty) return false;
    
    try {
      final uri = Uri.parse(endpoint);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Validate API key format
  static bool isValidApiKey(String apiKey) {
    return apiKey.isNotEmpty && apiKey.length >= 8;
  }
}
