import 'package:flutter/material.dart';
import '../services/centralized_platform_service.dart';
import '../models/business.dart';
import '../models/order.dart';
import '../l10n/app_localizations.dart';

class CentralizedPlatformPage extends StatefulWidget {
  final Business business;
  final List<Order> orders;

  const CentralizedPlatformPage({
    Key? key,
    required this.business,
    required this.orders,
  }) : super(key: key);

  @override
  State<CentralizedPlatformPage> createState() =>
      _CentralizedPlatformPageState();
}

class _CentralizedPlatformPageState extends State<CentralizedPlatformPage> {
  final CentralizedPlatformService _platformService =
      CentralizedPlatformService();

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
      final loc = AppLocalizations.of(context)!;
      _showError('${loc.failedToLoadPlatformStatus}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setupPlatform() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      final setupConfig = {
        "app_config": {"name": "delivery-platform-central", "region": "us"}
      };

      final result =
          await _platformService.setupCentralizedPlatform(setupConfig);

      if (result['success'] == true) {
        _showSuccess(loc.platformSetupCompletedSuccessfully);
        await _loadPlatformStatus();
      } else {
        _showError('${loc.platformSetupFailed}: ${result['message']}');
      }
    } catch (e) {
      _showError('${loc.errorSettingUpPlatform}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncAllBusinesses() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      final result = await _platformService.syncAllBusinessesToPlatform();
      _showSuccess(result['message'] ?? loc.allBusinessesSyncedSuccessfully);
      await _loadPlatformStatus();
    } catch (e) {
      _showError('${loc.errorSyncingBusinesses}: $e');
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
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.centralizedPlatform),
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
    final loc = AppLocalizations.of(context)!;
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
                  loc.platformConnection,
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
                  color:
                      isConnected ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Text(
                isConnected ? loc.connected : loc.disconnected,
                style: TextStyle(
                  color:
                      isConnected ? Colors.green.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_connectionStatus?['result']?['account'] != null) ...[
              const SizedBox(height: 8),
              Text(
                '${loc.account}: ${_connectionStatus!['result']['account']}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    final loc = AppLocalizations.of(context)!;
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
                  loc.syncStatus,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_syncStatus != null) ...[
              _buildSyncStatusRow(loc.platformApps,
                  _syncStatus!['platform_apps_count'].toString()),
              _buildSyncStatusRow(loc.localBusinesses,
                  _syncStatus!['local_businesses_count'].toString()),
              _buildSyncStatusRow(loc.syncRecommended,
                  _syncStatus!['sync_recommended'] ? loc.yes : loc.no),
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
    final loc = AppLocalizations.of(context)!;
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
                  '${loc.platformApps} (${_platformApps.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_platformApps.isEmpty)
              Text(loc.noAppsFound)
            else
              ...(_platformApps.take(5).map((app) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: app['state'] == 'up'
                                ? Colors.green
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(app['name'] ?? loc.unknown)),
                        Text(
                          app['state']?.toString().toUpperCase() ??
                              loc.unknown.toUpperCase(),
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
    final loc = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.actions,
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
                label: Text(loc.setupPlatform),
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
                label: Text(loc.syncAllBusinesses),
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
                label: Text(loc.refreshStatus),
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
