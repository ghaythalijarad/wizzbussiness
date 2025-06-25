import 'package:flutter/material.dart';
import '../services/centralized_platform_service.dart';
import '../models/business.dart';
import '../models/order.dart';

class CentralizedPlatformPage extends StatefulWidget {
  final Business business;
  final List<Order> orders;
  
  const CentralizedPlatformPage({
    Key? key,
    required this.business,
    required this.orders,
  }) : super(key: key);

  @override
  State<CentralizedPlatformPage> createState() => _CentralizedPlatformPageState();
}

class _CentralizedPlatformPageState extends State<CentralizedPlatformPage> {
  final CentralizedPlatformService _platformService = CentralizedPlatformService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _connectionStatus;
  Map<String, dynamic>? _syncStatus;
  List<dynamic> _platformApps = [];
  
  @override
  void initState() {
    super.initState();
    _loadPlatformStatus();
  }

  Future<void> _loadPlatformStatus() async {
    setState(() => _isLoading = true);
    
    try {
      // Test connection
      final connectionTest = await _platformService.testConnection();
      setState(() => _connectionStatus = connectionTest);
      
      // Get sync status
      final syncStatus = await _platformService.getPlatformSyncStatus();
      setState(() => _syncStatus = syncStatus);
      
      // Get platform apps
      final appsResult = await _platformService.getPlatformApps();
      setState(() => _platformApps = appsResult['apps'] ?? []);
      
    } catch (e) {
      _showError('Failed to load platform status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setupPlatform() async {
    setState(() => _isLoading = true);
    
    try {
      final setupConfig = {
        "app_config": {
          "name": "delivery-platform-central",
          "region": "us"
        }
      };
      
      final result = await _platformService.setupCentralizedPlatform(setupConfig);
      
      if (result['success'] == true) {
        _showSuccess('Platform setup completed successfully!');
        await _loadPlatformStatus();
      } else {
        _showError('Platform setup failed: ${result['message']}');
      }
    } catch (e) {
      _showError('Error setting up platform: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncAllBusinesses() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _platformService.syncAllBusinessesToPlatform();
      _showSuccess(result['message'] ?? 'All businesses synced successfully!');
      await _loadPlatformStatus();
    } catch (e) {
      _showError('Error syncing businesses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centralized Platform'),
        backgroundColor: const Color(0xFF3399FF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadPlatformStatus,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConnectionStatusCard(),
                  const SizedBox(height: 16),
                  _buildSyncStatusCard(),
                  const SizedBox(height: 16),
                  _buildPlatformAppsCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildConnectionStatusCard() {
    final isConnected = _connectionStatus?['result']?['status'] == 'connected';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Platform Connection',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isConnected ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isConnected ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  color: isConnected ? Colors.green.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_connectionStatus?['result']?['account'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Account: ${_connectionStatus!['result']['account']}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, color: Color(0xFF3399FF)),
                const SizedBox(width: 8),
                Text(
                  'Sync Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_syncStatus != null) ...[
              _buildSyncStatusRow('Platform Apps', _syncStatus!['platform_apps_count'].toString()),
              _buildSyncStatusRow('Local Businesses', _syncStatus!['local_businesses_count'].toString()),
              _buildSyncStatusRow('Sync Recommended', _syncStatus!['sync_recommended'] ? 'Yes' : 'No'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformAppsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.apps, color: Color(0xFF3399FF)),
                const SizedBox(width: 8),
                Text(
                  'Platform Apps (${_platformApps.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_platformApps.isEmpty)
              const Text('No apps found')
            else
              ...(_platformApps.take(5).map((app) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: app['state'] == 'up' ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(app['name'] ?? 'Unknown')),
                    Text(
                      app['state']?.toString().toUpperCase() ?? 'UNKNOWN',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ))),
            if (_platformApps.length > 5)
              Text('... and ${_platformApps.length - 5} more'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _setupPlatform,
                icon: const Icon(Icons.settings),
                label: const Text('Setup Platform'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3399FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _syncAllBusinesses,
                icon: const Icon(Icons.sync),
                label: const Text('Sync All Businesses'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loadPlatformStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Status'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
