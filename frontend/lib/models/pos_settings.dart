/// Enum for different POS system types
enum PosSystemType {
  genericApi,
  square,
  toast,
  clover,
  shopify,
  woocommerce,
}

/// Model class for POS (Point of Sale) settings
class PosSettings {
  String apiEndpoint;
  String apiKey;
  String? accessToken;
  String? locationId;
  PosSystemType systemType;
  bool enabled;
  bool autoSendOrders;
  bool autoAcceptOrders;
  int? timeoutSeconds;
  bool orderNotificationSound;
  bool displayOrderTimer;
  int maxProcessingTimeMinutes;
  String currency;
  double taxRate;
  double serviceChargeRate;
  int retryAttempts;
  bool testMode;
  
  // Receipt settings
  String businessName;
  String businessAddress;
  String businessPhone;
  bool showLogo;
  bool showQrCode;
  String footerMessage;
  String paperSize;
  
  // Printer settings
  bool printerEnabled;
  String printerName;
  String printerIp;
  bool autoPrintReceipts;
  bool printKitchenOrders;

  PosSettings({
    this.apiEndpoint = '',
    this.apiKey = '',
    this.accessToken,
    this.locationId,
    this.systemType = PosSystemType.genericApi,
    this.enabled = false,
    this.autoSendOrders = false,
    this.autoAcceptOrders = true,
    this.timeoutSeconds = 30,
    this.orderNotificationSound = true,
    this.displayOrderTimer = true,
    this.maxProcessingTimeMinutes = 30,
    this.currency = 'USD',
    this.taxRate = 0.0,
    this.serviceChargeRate = 0.0,
    this.retryAttempts = 3,
    this.testMode = false,
    this.businessName = '',
    this.businessAddress = '',
    this.businessPhone = '',
    this.showLogo = false,
    this.showQrCode = true,
    this.footerMessage = 'Thank you for your business!',
    this.paperSize = 'A4',
    this.printerEnabled = false,
    this.printerName = '',
    this.printerIp = '',
    this.autoPrintReceipts = false,
    this.printKitchenOrders = true,
  });

  /// Create PosSettings from JSON
  factory PosSettings.fromJson(Map<String, dynamic> json) {
    return PosSettings(
      apiEndpoint: json['apiEndpoint'] ?? '',
      apiKey: json['apiKey'] ?? '',
      accessToken: json['accessToken'],
      locationId: json['locationId'],
      systemType: _parseSystemType(json['systemType']),
      enabled: json['enabled'] ?? false,
      autoSendOrders: json['autoSendOrders'] ?? false,
      autoAcceptOrders: json['autoAcceptOrders'] ?? true,
      timeoutSeconds: json['timeoutSeconds'] ?? 30,
      orderNotificationSound: json['orderNotificationSound'] ?? true,
      displayOrderTimer: json['displayOrderTimer'] ?? true,
      maxProcessingTimeMinutes: json['maxProcessingTimeMinutes'] ?? 30,
      currency: json['currency'] ?? 'USD',
      taxRate: (json['taxRate'] ?? 0.0).toDouble(),
      serviceChargeRate: (json['serviceChargeRate'] ?? 0.0).toDouble(),
      retryAttempts: json['retryAttempts'] ?? 3,
      testMode: json['testMode'] ?? false,
      businessName: json['businessName'] ?? '',
      businessAddress: json['businessAddress'] ?? '',
      businessPhone: json['businessPhone'] ?? '',
      showLogo: json['showLogo'] ?? false,
      showQrCode: json['showQrCode'] ?? true,
      footerMessage: json['footerMessage'] ?? 'Thank you for your business!',
      paperSize: json['paperSize'] ?? 'A4',
      printerEnabled: json['printerEnabled'] ?? false,
      printerName: json['printerName'] ?? '',
      printerIp: json['printerIp'] ?? '',
      autoPrintReceipts: json['autoPrintReceipts'] ?? false,
      printKitchenOrders: json['printKitchenOrders'] ?? true,
    );
  }

  /// Convert PosSettings to JSON
  Map<String, dynamic> toJson() {
    return {
      'apiEndpoint': apiEndpoint,
      'apiKey': apiKey,
      'accessToken': accessToken,
      'locationId': locationId,
      'systemType': systemType.toString().split('.').last,
      'enabled': enabled,
      'autoSendOrders': autoSendOrders,
      'autoAcceptOrders': autoAcceptOrders,
      'timeoutSeconds': timeoutSeconds,
      'orderNotificationSound': orderNotificationSound,
      'displayOrderTimer': displayOrderTimer,
      'maxProcessingTimeMinutes': maxProcessingTimeMinutes,
      'currency': currency,
      'taxRate': taxRate,
      'serviceChargeRate': serviceChargeRate,
      'retryAttempts': retryAttempts,
      'testMode': testMode,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
      'showLogo': showLogo,
      'showQrCode': showQrCode,
      'footerMessage': footerMessage,
      'paperSize': paperSize,
      'printerEnabled': printerEnabled,
      'printerName': printerName,
      'printerIp': printerIp,
      'autoPrintReceipts': autoPrintReceipts,
      'printKitchenOrders': printKitchenOrders,
    };
  }

  /// Create a copy of PosSettings with updated values
  PosSettings copyWith({
    String? apiEndpoint,
    String? apiKey,
    String? accessToken,
    String? locationId,
    PosSystemType? systemType,
    bool? enabled,
    bool? autoSendOrders,
    bool? autoAcceptOrders,
    bool? orderNotificationSound,
    bool? displayOrderTimer,
    int? maxProcessingTimeMinutes,
    String? currency,
    double? taxRate,
    double? serviceChargeRate,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    bool? showLogo,
    bool? showQrCode,
    String? footerMessage,
    String? paperSize,
    bool? printerEnabled,
    String? printerName,
    String? printerIp,
    bool? autoPrintReceipts,
    bool? printKitchenOrders,
  }) {
    return PosSettings(
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      apiKey: apiKey ?? this.apiKey,
      accessToken: accessToken ?? this.accessToken,
      locationId: locationId ?? this.locationId,
      systemType: systemType ?? this.systemType,
      enabled: enabled ?? this.enabled,
      autoSendOrders: autoSendOrders ?? this.autoSendOrders,
      autoAcceptOrders: autoAcceptOrders ?? this.autoAcceptOrders,
      orderNotificationSound: orderNotificationSound ?? this.orderNotificationSound,
      displayOrderTimer: displayOrderTimer ?? this.displayOrderTimer,
      maxProcessingTimeMinutes: maxProcessingTimeMinutes ?? this.maxProcessingTimeMinutes,
      currency: currency ?? this.currency,
      taxRate: taxRate ?? this.taxRate,
      serviceChargeRate: serviceChargeRate ?? this.serviceChargeRate,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      showLogo: showLogo ?? this.showLogo,
      showQrCode: showQrCode ?? this.showQrCode,
      footerMessage: footerMessage ?? this.footerMessage,
      paperSize: paperSize ?? this.paperSize,
      printerEnabled: printerEnabled ?? this.printerEnabled,
      printerName: printerName ?? this.printerName,
      printerIp: printerIp ?? this.printerIp,
      autoPrintReceipts: autoPrintReceipts ?? this.autoPrintReceipts,
      printKitchenOrders: printKitchenOrders ?? this.printKitchenOrders,
    );
  }

  /// Helper method to parse system type from string
  static PosSystemType _parseSystemType(dynamic value) {
    if (value == null) return PosSystemType.genericApi;
    
    final stringValue = value.toString().toLowerCase();
    switch (stringValue) {
      case 'square':
        return PosSystemType.square;
      case 'toast':
        return PosSystemType.toast;
      case 'clover':
        return PosSystemType.clover;
      case 'shopify':
        return PosSystemType.shopify;
      case 'woocommerce':
        return PosSystemType.woocommerce;
      default:
        return PosSystemType.genericApi;
    }
  }

  @override
  String toString() {
    return 'PosSettings(apiEndpoint: $apiEndpoint, systemType: $systemType, enabled: $enabled)';
  }
}

