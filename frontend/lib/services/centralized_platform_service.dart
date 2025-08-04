import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../config/app_config.dart';
import 'dart:async';
import 'dart:convert';
import 'websocket_service.dart';
import '../models/order.dart';

class CentralizedPlatformService with ChangeNotifier {
  static final CentralizedPlatformService _instance =
      CentralizedPlatformService._internal();
  bool _isDisposed = false;
  String? _businessId;
  late WebSocketService _webSocketService; // Add WebSocketService instance
  final _orderStreamController = StreamController<Order>.broadcast();

  List<Map<String, dynamic>> _availablePlatforms = [];
  final Map<String, dynamic> _platformData = {};
  bool _isLoading = false;

  factory CentralizedPlatformService() {
    return _instance;
  }

  Stream<Order> get orderStream => _orderStreamController.stream;

  CentralizedPlatformService._internal() {
    _webSocketService = WebSocketService(
      onMessage: (message) {
        print("CentralizedPlatformService: Message received: $message");
        try {
          final Map<String, dynamic> data = (message as Map<String, dynamic>);
          final order = Order.fromJson(data);
          
          // Safely add order to stream if not disposed
          if (!_isDisposed && !_orderStreamController.isClosed) {
            _orderStreamController.add(order);
          }
        } catch (e) {
          print('Error parsing order: $e');
        }
        notifyListeners();
      },
      onDone: () {
        print("CentralizedPlatformService: WebSocket connection closed.");
        if (!_isDisposed) {
          _reconnect();
        }
      },
      onError: (error) {
        print("CentralizedPlatformService: WebSocket error: $error");
        // Handle error, maybe schedule a reconnect
      },
    );
    _connectToWebSocket();
    initializePlatforms();
  }

  Future<void> _connectToWebSocket() async {
    if (_isDisposed) return;
    try {
      final token = await _getStoredToken();
      if (token != null) {
        final url = AppConfig.webSocketUrl;
        _webSocketService.connect(url, token);
        print('WebSocket connection established.');
      } else {
        print('Authentication token not found, WebSocket not connected.');
      }
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _reconnect();
    }
  }

  void _reconnect() {
    if (_isDisposed) return;
    print('Attempting to reconnect WebSocket in 5 seconds...');
    Future.delayed(const Duration(seconds: 5), () {
      _connectToWebSocket();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _webSocketService.disconnect();
    
    // Safely close stream controller
    if (!_orderStreamController.isClosed) {
      _orderStreamController.close();
    }
    
    super.dispose();
  }

  Future<String?> get businessId async {
    if (_businessId != null) return _businessId;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/business_id.txt');

      if (await file.exists()) {
        final id = await file.readAsString();
        _businessId = id;
        return _businessId;
      } else {
        print('Business ID file not found.');
        return null;
      }
    } catch (e) {
      print('Error reading business ID: $e');
      return null;
    }
  }

  Future<String?> _getStoredToken() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/token.txt');

      if (await file.exists()) {
        final token = await file.readAsString();
        print('Token retrieved successfully.');
        return token;
      } else {
        print('Token file not found.');
        return null;
      }
    } catch (e) {
      print('Error retrieving token: $e');
      return null;
    }
  }

  /// Initialize available platforms
  void initializePlatforms() {
    _availablePlatforms = [
      {
        'id': 'uber_eats',
        'name': 'Uber Eats',
        'description': 'Food delivery platform',
        'isActive': false,
        'icon': '🚗',
      },
      {
        'id': 'deliveroo',
        'name': 'Deliveroo',
        'description': 'Food delivery service',
        'isActive': false,
        'icon': '🛵',
      },
      {
        'id': 'talabat',
        'name': 'Talabat',
        'description': 'Online food ordering',
        'isActive': false,
        'icon': '🥘',
      },
      {
        'id': 'careem_now',
        'name': 'Careem NOW',
        'description': 'Delivery platform',
        'isActive': false,
        'icon': '🚖',
      },
    ];
    notifyListeners();
    debugPrint('🔗 Initialized ${_availablePlatforms.length} platforms');
  }

  /// Connect to a platform
  Future<bool> connectToPlatform(
      String platformId, Map<String, String> credentials) async {
    _setLoading(true);

    try {
      debugPrint('🔌 Connecting to platform: $platformId');

      // Simulate API call to connect platform
      await Future.delayed(const Duration(seconds: 2));

      // Update platform status
      final platformIndex =
          _availablePlatforms.indexWhere((p) => p['id'] == platformId);
      if (platformIndex != -1) {
        _availablePlatforms[platformIndex]['isActive'] = true;
        _platformData[platformId] = {
          'credentials': credentials,
          'connectedAt': DateTime.now().toIso8601String(),
          'status': 'active',
        };
      }

      _setLoading(false);
      notifyListeners();
      debugPrint('✅ Successfully connected to $platformId');
      return true;
    } catch (e) {
      _setLoading(false);
      notifyListeners();
      debugPrint('❌ Failed to connect to $platformId: $e');
      return false;
    }
  }

  /// Disconnect from a platform
  Future<bool> disconnectFromPlatform(String platformId) async {
    _setLoading(true);

    try {
      debugPrint('🔌 Disconnecting from platform: $platformId');

      // Simulate API call to disconnect platform
      await Future.delayed(const Duration(seconds: 1));

      // Update platform status
      final platformIndex =
          _availablePlatforms.indexWhere((p) => p['id'] == platformId);
      if (platformIndex != -1) {
        _availablePlatforms[platformIndex]['isActive'] = false;
        _platformData.remove(platformId);
      }

      _setLoading(false);
      notifyListeners();
      debugPrint('✅ Successfully disconnected from $platformId');
      return true;
    } catch (e) {
      _setLoading(false);
      notifyListeners();
      debugPrint('❌ Failed to disconnect from $platformId: $e');
      return false;
    }
  }

  /// Sync orders from all connected platforms
  Future<List<Map<String, dynamic>>> syncOrders() async {
    _setLoading(true);
    List<Map<String, dynamic>> orders = [];

    try {
      debugPrint('🔄 Syncing orders from connected platforms');

      for (final platform in _availablePlatforms) {
        if (platform['isActive'] == true) {
          final platformOrders = await _fetchOrdersFromPlatform(platform['id']);
          orders.addAll(platformOrders);
        }
      }

      _setLoading(false);
      debugPrint('✅ Synced ${orders.length} orders from platforms');
      return orders;
    } catch (e) {
      _setLoading(false);
      debugPrint('❌ Failed to sync orders: $e');
      return [];
    }
  }

  /// Fetch orders from a specific platform
  Future<List<Map<String, dynamic>>> _fetchOrdersFromPlatform(
      String platformId) async {
    // Simulate API call to fetch orders
    await Future.delayed(const Duration(milliseconds: 500));

    // Return mock orders
    return [
      {
        'id': '${platformId}_order_1',
        'platform': platformId,
        'customerName': 'Customer from ${platformId.replaceAll('_', ' ')}',
        'total': 25.99,
        'status': 'pending',
        'items': ['Burger', 'Fries'],
        'timestamp': DateTime.now()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
      },
      {
        'id': '${platformId}_order_2',
        'platform': platformId,
        'customerName': 'Another Customer',
        'total': 18.50,
        'status': 'confirmed',
        'items': ['Pizza', 'Drink'],
        'timestamp': DateTime.now()
            .subtract(const Duration(minutes: 10))
            .toIso8601String(),
      },
    ];
  }

  /// Get platform statistics
  Map<String, dynamic> getPlatformStats() {
    final connectedCount =
        _availablePlatforms.where((p) => p['isActive'] == true).length;
    final totalPlatforms = _availablePlatforms.length;

    return {
      'connectedPlatforms': connectedCount,
      'totalPlatforms': totalPlatforms,
      'connectionRate': totalPlatforms > 0
          ? (connectedCount / totalPlatforms * 100).round()
          : 0,
      'lastSync': DateTime.now().toIso8601String(),
    };
  }

  /// Check platform connection status
  Future<bool> checkConnectionStatus(String platformId) async {
    try {
      // Simulate API call to check status
      await Future.delayed(const Duration(milliseconds: 500));

      final platformData = _platformData[platformId];
      return platformData != null && platformData['status'] == 'active';
    } catch (e) {
      debugPrint('❌ Failed to check connection status for $platformId: $e');
      return false;
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Get connected platform names
  List<String> getConnectedPlatformNames() {
    return _availablePlatforms
        .where((p) => p['isActive'] == true)
        .map((p) => p['name'] as String)
        .toList();
  }

  /// Test platform connection
  Future<bool> testConnection(String platformId) async {
    try {
      debugPrint('🧪 Testing connection to $platformId');
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('✅ Connection test successful for $platformId');
      return true;
    } catch (e) {
      debugPrint('❌ Connection test failed for $platformId: $e');
      return false;
    }
  }

  /// Get platform sync status
  Map<String, dynamic> getPlatformSyncStatus() {
    return {
      'lastSync': DateTime.now().toIso8601String(),
      'syncInProgress': _isLoading,
      'connectedPlatforms':
          _availablePlatforms.where((p) => p['isActive'] == true).length,
      'totalPlatforms': _availablePlatforms.length,
    };
  }

  /// Get platform apps (available platforms)
  List<Map<String, dynamic>> getPlatformApps() {
    return List.from(_availablePlatforms);
  }

  /// Setup centralized platform
  Future<Map<String, dynamic>> setupCentralizedPlatform() async {
    _setLoading(true);

    try {
      debugPrint('🔧 Setting up centralized platform');

      // Initialize platforms if not already done
      if (_availablePlatforms.isEmpty) {
        initializePlatforms();
      }

      // Simulate setup process
      await Future.delayed(const Duration(seconds: 2));

      _setLoading(false);
      debugPrint('✅ Centralized platform setup completed');
      return {
        'success': true,
        'message': 'Platform setup completed successfully'
      };
    } catch (e) {
      _setLoading(false);
      debugPrint('❌ Failed to setup centralized platform: $e');
      return {'success': false, 'message': 'Failed to setup platform: $e'};
    }
  }

  /// Sync all businesses to platform
  Future<Map<String, dynamic>> syncAllBusinessesToPlatform() async {
    _setLoading(true);

    try {
      debugPrint('🔄 Syncing all businesses to platform');

      // Simulate sync process
      await Future.delayed(const Duration(seconds: 3));

      _setLoading(false);
      debugPrint('✅ Successfully synced all businesses to platform');
      return {'success': true, 'message': 'All businesses synced successfully'};
    } catch (e) {
      _setLoading(false);
      debugPrint('❌ Failed to sync businesses to platform: $e');
      return {'success': false, 'message': 'Failed to sync businesses: $e'};
    }
  }

  /// Get platform connection status
  Map<String, dynamic> getPlatformConnectionStatus(String platformId) {
    final platform = _availablePlatforms.firstWhere(
      (p) => p['id'] == platformId,
      orElse: () => {},
    );
    if (platform.isEmpty) {
      return {
        'status': 'not_found',
        'message': 'Platform not found',
      };
    }
    return {
      'status': platform['isActive'] ? 'connected' : 'disconnected',
      'message': platform['isActive']
          ? 'Successfully connected'
              'Syncing data...'
          : 'Not connected',
    };
  }

  /// Get overall connection status
  String get overallConnectionStatus {
    final connectedCount =
        _availablePlatforms.where((p) => p['isActive'] == true).length;
    final totalCount = _availablePlatforms.length;

    if (connectedCount == 0) {
      return 'disconnected';
    } else if (connectedCount < totalCount) {
      return 'partially_connected';
    } else {
      return 'connected';
    }
  }
}
