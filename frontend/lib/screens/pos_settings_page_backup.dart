import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/business.dart';
import '../models/pos_settings.dart';
import '../services/pos_service.dart';
import '../services/api_service.dart';
import '../services/app_auth_service.dart';
import '../screens/login_page.dart';

class PosSettingsPage extends StatefulWidget {
  final Business business;

  const PosSettingsPage({
    Key? key,
    required this.business,
  }) : super(key: key);

  @override
  _PosSettingsPageState createState() => _PosSettingsPageState();
}

class _PosSettingsPageState extends State<PosSettingsPage>
    with TickerProviderStateMixin {
  late PosSettings _posSettings;
  bool _isLoading = false;
  bool _isTesting = false;
  bool _isLoadingSettings = true;
  bool _isLoadingSyncLogs = false;
  bool _isInitializing = true;
  List<Map<String, dynamic>> _syncLogs = [];
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _apiEndpointController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _accessTokenController = TextEditingController();
  final _locationIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _validateAuthenticationAndInitialize();
  }

  Future<void> _validateAuthenticationAndInitialize() async {
    try {
      // Check if business ID is provided
      if (widget.business.id.isEmpty) {
        _showAuthenticationRequiredDialog();
        return;
      }

      // Check if user is signed in
      final isSignedIn = await AppAuthService.isSignedIn();
      if (!isSignedIn) {
        _showAuthenticationRequiredDialog();
        return;
      }

      // Verify current user and access token
      final currentUser = await AppAuthService.getCurrentUser();
      final accessToken = await AppAuthService.getAccessToken();

      if (currentUser == null || accessToken == null) {
        _showAuthenticationRequiredDialog();
        return;
      }

      // If all checks pass, proceed with initialization
      setState(() {
        _isInitializing = false;
      });

      // Load POS settings and sync logs after authentication is verified
      _loadPosSettings();
      _loadSyncLogs();
    } catch (e) {
      print('Authentication validation failed: $e');
      _showAuthenticationRequiredDialog();
    }
  }

  void _showAuthenticationRequiredDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(
          Icons.security,
          color: Color(0xFF00C1E8),
          size: 48,
        ),
        title: Text(
          loc.userNotLoggedIn,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF001133),
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Please sign in to access POS settings',
          style: TextStyle(
            color: const Color(0xFF001133).withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => _navigateToLogin(),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF00C1E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(loc.signIn),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => LoginPage(
          onLanguageChanged: (locale) {
            // Handle language change if needed
          },
        ),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _apiEndpointController.dispose();
    _apiKeyController.dispose();
    _accessTokenController.dispose();
    _locationIdController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadPosSettings() {
    // Load POS settings from business settings
    final posSettingsData =
        widget.business.settings['pos'] as Map<String, dynamic>?;
    if (posSettingsData != null) {
      _posSettings = PosSettings.fromJson(posSettingsData);
    } else {
      _posSettings = PosSettings();
    }

    // Update controllers
    _apiEndpointController.text = _posSettings.apiEndpoint;
    _apiKeyController.text = _posSettings.apiKey;
    _accessTokenController.text = _posSettings.accessToken ?? '';
    _locationIdController.text = _posSettings.locationId ?? '';

    setState(() {
      _isLoadingSettings = false;
    });
  }

  void _savePosSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Update settings from form
      _posSettings.apiEndpoint = _apiEndpointController.text.trim();
      _posSettings.apiKey = _apiKeyController.text.trim();
      _posSettings.accessToken = _accessTokenController.text.trim().isEmpty
          ? null
          : _accessTokenController.text.trim();
      _posSettings.locationId = _locationIdController.text.trim().isEmpty
          ? null
          : _locationIdController.text.trim();

      // Use API service to save settings
      final apiService = ApiService();
      await apiService.updatePosSettings(
          widget.business.id, _posSettings.toJson());

      // Update local business settings as backup
      widget.business.updateSettings('pos', 'settings', _posSettings.toJson());

      setState(() => _isLoading = false);

      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.posSettingsUpdated),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save POS settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    try {
      // Create test configuration
      final testConfig = {
        'system_type': _posSettings.systemType.toString().split('.').last,
        'api_endpoint': _apiEndpointController.text.trim(),
        'api_key': _apiKeyController.text.trim(),
        'access_token': _accessTokenController.text.trim().isEmpty
            ? null
            : _accessTokenController.text.trim(),
        'location_id': _locationIdController.text.trim().isEmpty
            ? null
            : _locationIdController.text.trim(),
      };

      // Use API service to test connection
      final apiService = ApiService();
      final result =
          await apiService.testPosConnection(widget.business.id, testConfig);

      setState(() => _isTesting = false);

      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true
              ? loc.connectionSuccessful
              : loc.connectionFailed),
          backgroundColor:
              result['success'] == true ? Colors.green : Colors.red,
        ),
      );

      // Show detailed result in dialog
      _showConnectionResultDialog(result);
    } catch (e) {
      setState(() => _isTesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showConnectionResultDialog(Map<String, dynamic> result) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.testConnection),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result['success'] == true ? Icons.check_circle : Icons.error,
                  color: result['success'] == true ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(result['message'] ?? 'Unknown result'),
              ],
            ),
            if (result['response_time_ms'] != null) ...[
              const SizedBox(height: 8),
              Text('Response time: ${result['response_time_ms']}ms'),
            ],
            if (result['error_details'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${result['error_details']}',
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTypeSelector() {
    final loc = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.posSystemType,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PosSystemType>(
              value: _posSettings.systemType,
              decoration: InputDecoration(
                labelText: loc.selectPosSystem,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.point_of_sale),
              ),
              items: PosSystemType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(PosService.getSystemTypeName(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _posSettings.systemType = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiConfigCard() {
    final loc = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.api, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  loc.apiConfiguration,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiEndpointController,
              decoration: InputDecoration(
                labelText: loc.apiEndpoint,
                hintText: 'https://api.yourpos.com/v1',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.link),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return loc.pleaseEnterApiEndpoint;
                }
                if (!PosService.isValidApiEndpoint(value.trim())) {
                  return loc.pleaseEnterValidUrl;
                }
                return null;
              },
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: loc.apiKey,
                hintText: loc.enterApiKey,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_copy),
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: _apiKeyController.text));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.copiedToClipboard)),
                      );
                    }
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return loc.pleaseEnterApiKey;
                }
                return null;
              },
              obscureText: true,
            ),
            if (_posSettings.systemType != PosSystemType.genericApi) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _accessTokenController,
                decoration: InputDecoration(
                  labelText: loc.accessToken,
                  hintText: loc.enterAccessToken,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.token),
                ),
                obscureText: true,
              ),
            ],
            if (_posSettings.systemType == PosSystemType.square ||
                _posSettings.systemType == PosSystemType.toast ||
                _posSettings.systemType == PosSystemType.clover) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationIdController,
                decoration: InputDecoration(
                  labelText: loc.locationId,
                  hintText: loc.enterLocationId,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard() {
    final loc = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  loc.posIntegrationSettings,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(loc.enablePosIntegration),
              subtitle: Text(loc.enablePosIntegrationDescription),
              value: _posSettings.enabled,
              onChanged: (value) {
                setState(() {
                  _posSettings.enabled = value;
                });
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            const Divider(),
            SwitchListTile(
              title: Text(loc.autoSendOrders),
              subtitle: Text(loc.autoSendOrdersDescription),
              value: _posSettings.autoSendOrders,
              onChanged: _posSettings.enabled
                  ? (value) {
                      setState(() {
                        _posSettings.autoSendOrders = value;
                      });
                    }
                  : null,
              activeColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard() {
    final loc = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _posSettings.enabled ? Icons.check_circle : Icons.cancel,
                  color: _posSettings.enabled ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.connectionStatus,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _posSettings.enabled
                  ? loc.posIntegrationEnabled
                  : loc.posIntegrationDisabled,
              style: TextStyle(
                color: _posSettings.enabled ? Colors.green : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_posSettings.enabled) ...[
              const SizedBox(height: 8),
              Text(
                '${loc.system}: ${PosService.getSystemTypeName(_posSettings.systemType)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_posSettings.apiEndpoint.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${loc.endpoint}: ${_posSettings.apiEndpoint}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering),
              label: Text(_isTesting ? loc.testing : loc.testConnection),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _savePosSettings,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? loc.saving : loc.saveSettings),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSyncLogs() async {
    setState(() => _isLoadingSyncLogs = true);

    try {
      final apiService = ApiService();
      final logs = await apiService.getPosSyncLogs(widget.business.id);
      setState(() {
        _syncLogs = logs;
        _isLoadingSyncLogs = false;
      });
    } catch (e) {
      setState(() => _isLoadingSyncLogs = false);
      print('Error loading sync logs: $e');
    }
  }

  // Enhanced sync logs display
  Widget _buildSyncLogsTab() {
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Sync logs header with refresh button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.posSyncLogs,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: _loadSyncLogs,
                icon: _isLoadingSyncLogs
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        // Sync logs list
        Expanded(
          child: _isLoadingSyncLogs
              ? const Center(child: CircularProgressIndicator())
              : _syncLogs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            loc.noSyncLogsFound,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _syncLogs.length,
                      itemBuilder: (context, index) {
                        final log = _syncLogs[index];
                        return _buildSyncLogCard(log);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSyncLogCard(Map<String, dynamic> log) {
    final loc = AppLocalizations.of(context)!;
    final isSuccess = log['sync_status'] == 'success';
    final timestamp =
        DateTime.tryParse(log['sync_timestamp'] ?? '') ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSuccess ? Colors.green : Colors.red,
          child: Icon(
            isSuccess ? Icons.check : Icons.error,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text('Order #${log['order_id'] ?? 'Unknown'}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${loc.system}: ${log['pos_system_type'] ?? 'Unknown'}'),
            Text('${loc.status}: ${isSuccess ? loc.successful : loc.failed}'),
            if (log['error_message'] != null && !isSuccess)
              Text(
                log['error_message'],
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
          ],
        ),
        trailing: Text(
          '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () => _showSyncLogDetails(log),
      ),
    );
  }

  void _showSyncLogDetails(Map<String, dynamic> log) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${loc.syncLogDetails} #${log['order_id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(loc.system, log['pos_system_type'] ?? 'Unknown'),
            _buildDetailRow(loc.status, log['sync_status'] ?? 'Unknown'),
            _buildDetailRow(loc.syncTime, log['sync_timestamp'] ?? 'Unknown'),
            if (log['pos_order_id'] != null)
              _buildDetailRow(loc.posOrderId, log['pos_order_id']),
            if (log['error_message'] != null)
              _buildDetailRow(loc.errorMessage, log['error_message']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.close),
          ),
          if (log['sync_status'] == 'failed')
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retrySyncOrder(log['order_id']);
              },
              child: Text(loc.retrySync),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _retrySyncOrder(String orderId) async {
    try {
      final apiService = ApiService();
      await apiService.syncOrderToPos(widget.business.id, orderId);

      // Refresh sync logs
      _loadSyncLogs();

      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.orderSyncRetryInitiated),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to retry sync: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Advanced settings tab
  Widget _buildAdvancedSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAdvancedConfigCard(),
        const SizedBox(height: 16),
        _buildWebhooksCard(),
        const SizedBox(height: 16),
        _buildSecurityCard(),
        const SizedBox(height: 24), // Extra padding at bottom
      ],
    );
  }

  Widget _buildAdvancedConfigCard() {
    final loc = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.advancedConfiguration,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue:
                        _posSettings.timeoutSeconds?.toString() ?? '30',
                    decoration: InputDecoration(
                      labelText: loc.timeoutSeconds,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.timer),
                      suffixText: 'sec',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final timeout = int.tryParse(value);
                      if (timeout != null && timeout >= 5 && timeout <= 300) {
                        _posSettings.timeoutSeconds = timeout;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _posSettings.retryAttempts?.toString() ?? '3',
                    decoration: InputDecoration(
                      labelText: loc.retryAttempts,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.replay),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final attempts = int.tryParse(value);
                      if (attempts != null && attempts >= 0 && attempts <= 10) {
                        _posSettings.retryAttempts = attempts;
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(loc.testMode),
              subtitle: Text(loc.testModeDescription),
              value: _posSettings.testMode ?? false,
              onChanged: (value) {
                setState(() {
                  _posSettings.testMode = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebhooksCard() {
    final loc = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.webhooksIntegration,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              loc.webhooksDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showWebhookSetupDialog(),
              icon: const Icon(Icons.webhook),
              label: Text(loc.configureWebhooks),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    final loc = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.securitySettings,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.security),
              title: Text(loc.encryptionStatus),
              subtitle: Text(loc.encryptionEnabled),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: Text(loc.apiKeyRotation),
              subtitle: Text(loc.lastRotated),
              trailing: TextButton(
                onPressed: () => _showApiKeyRotationDialog(),
                child: Text(loc.rotate),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Help and configuration guides tab
  Widget _buildHelpTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSystemGuideCard(),
        const SizedBox(height: 16),
        _buildTroubleshootingCard(),
        const SizedBox(height: 16),
        _buildSupportCard(),
        const SizedBox(height: 24), // Extra padding at bottom
      ],
    );
  }

  Widget _buildSystemGuideCard() {
    final loc = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.systemSetupGuides,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ..._buildSystemGuideButtons(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSystemGuideButtons() {
    final loc = AppLocalizations.of(context)!;
    final systems = [
      {'type': 'Square', 'icon': Icons.payment},
      {'type': 'Toast POS', 'icon': Icons.restaurant},
      {'type': 'Clover', 'icon': Icons.point_of_sale},
      {'type': 'Shopify POS', 'icon': Icons.store},
      {'type': 'Generic API', 'icon': Icons.api},
    ];

    return systems.map((system) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(system['icon'] as IconData),
          title: Text('${system['type']} ${loc.setupGuide}'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showSystemGuide(system['type'] as String),
        ),
      );
    }).toList();
  }

  Widget _buildTroubleshootingCard() {
    final loc = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.troubleshooting,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text(loc.connectionIssues),
              onTap: () => _showTroubleshootingGuide('connection'),
            ),
            ListTile(
              leading: const Icon(Icons.sync_problem),
              title: Text(loc.syncFailures),
              onTap: () => _showTroubleshootingGuide('sync'),
            ),
            ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text(loc.apiErrors),
              onTap: () => _showTroubleshootingGuide('api'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard() {
    final loc = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.supportContact,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.chat),
              title: Text(loc.liveChat),
              subtitle: Text(loc.availableWeekdays),
              onTap: () => _openLiveChat(),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(loc.emailSupport),
              subtitle: const Text('support@orderreceiver.com'),
              onTap: () => _openEmailSupport(),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods
  void _showWebhookSetupDialog() {
    final loc = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(loc.webhookSetupTitle),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.webhookSetupDescription,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (String step in [
                        loc.webhookStep1,
                        loc.webhookStep2,
                        loc.webhookStep3,
                        loc.webhookStep4,
                        loc.webhookStep5,
                        loc.webhookStep6,
                        loc.webhookStep7,
                      ]) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.webhook,
                                size: 16,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  step,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApiKeyRotationDialog() {
    final loc = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(loc.apiKeyRotationTitle),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.apiKeyRotationDescription,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (String step in [
                        loc.rotationStep1,
                        loc.rotationStep2,
                        loc.rotationStep3,
                        loc.rotationStep4,
                        loc.rotationStep5,
                        loc.rotationStep6,
                      ]) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.security,
                                size: 16,
                                color: Colors.orange.shade600,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  step,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
        ],
      ),
    );
  }

  void _showSystemGuide(String systemType) {
    final loc = AppLocalizations.of(context)!;
    String title;
    List<String> steps;
    String description;

    switch (systemType) {
      case 'Square':
        title = loc.squareSetupTitle;
        description = loc.squareSetupDescription;
        steps = [
          loc.squareStep1,
          loc.squareStep2,
          loc.squareStep3,
          loc.squareStep4,
          loc.squareStep5,
          loc.squareStep6,
          loc.squareStep7,
          loc.squareStep8,
        ];
        break;
      case 'Toast POS':
        title = loc.toastSetupTitle;
        description = loc.toastSetupDescription;
        steps = [
          loc.toastStep1,
          loc.toastStep2,
          loc.toastStep3,
          loc.toastStep4,
          loc.toastStep5,
          loc.toastStep6,
          loc.toastStep7,
          loc.toastStep8,
        ];
        break;
      case 'Clover':
        title = loc.cloverSetupTitle;
        description = loc.cloverSetupDescription;
        steps = [
          loc.cloverStep1,
          loc.cloverStep2,
          loc.cloverStep3,
          loc.cloverStep4,
          loc.cloverStep5,
          loc.cloverStep6,
          loc.cloverStep7,
          loc.cloverStep8,
        ];
        break;
      case 'Shopify POS':
        title = loc.shopifySetupTitle;
        description = loc.shopifySetupDescription;
        steps = [
          loc.shopifyStep1,
          loc.shopifyStep2,
          loc.shopifyStep3,
          loc.shopifyStep4,
          loc.shopifyStep5,
          loc.shopifyStep6,
          loc.shopifyStep7,
          loc.shopifyStep8,
        ];
        break;
      case 'Generic API':
        title = loc.genericApiSetupTitle;
        description = loc.genericApiSetupDescription;
        steps = [
          loc.genericStep1,
          loc.genericStep2,
          loc.genericStep3,
          loc.genericStep4,
          loc.genericStep5,
          loc.genericStep6,
          loc.genericStep7,
          loc.genericStep8,
        ];
        break;
      default:
        title = '$systemType Setup Guide';
        description = 'Setup guide for $systemType coming soon...';
        steps = [];
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(title),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (steps.isNotEmpty) ...[
                        for (String step in steps) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    step,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTroubleshootingGuide(String issueType) {
    final loc = AppLocalizations.of(context)!;
    String title;
    List<String> issues;
    String description;

    switch (issueType) {
      case 'connection':
        title = loc.connectionIssues;
        description = loc.connectionIssuesDescription;
        issues = [
          loc.connectionIssue1,
          loc.connectionIssue2,
          loc.connectionIssue3,
          loc.connectionIssue4,
          loc.connectionIssue5,
          loc.connectionIssue6,
          loc.connectionIssue7,
        ];
        break;
      case 'sync':
        title = loc.syncFailures;
        description = loc.syncFailuresDescription;
        issues = [
          loc.syncIssue1,
          loc.syncIssue2,
          loc.syncIssue3,
          loc.syncIssue4,
          loc.syncIssue5,
          loc.syncIssue6,
          loc.syncIssue7,
        ];
        break;
      case 'api':
        title = loc.apiErrors;
        description = loc.apiErrorsDescription;
        issues = [
          loc.apiIssue1,
          loc.apiIssue2,
          loc.apiIssue3,
          loc.apiIssue4,
          loc.apiIssue5,
          loc.apiIssue6,
          loc.apiIssue7,
        ];
        break;
      default:
        title = 'Troubleshooting Guide';
        description = 'Troubleshooting guide coming soon...';
        issues = [];
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(title),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (issues.isNotEmpty) ...[
                        for (String issue in issues) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_outlined,
                                  size: 16,
                                  color: Colors.red.shade600,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    issue,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLiveChat() {
    final loc = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(loc.liveChat),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.liveChatDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.liveChatHours,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.liveChatComingSoon),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.startChat),
          ),
        ],
      ),
    );
  }

  void _openEmailSupport() {
    final loc = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.email_outlined,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(loc.emailSupport),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.emailSupportDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email,
                    size: 16,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      'support@orderreceiver.com',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.emailResponseTime,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.emailSupportOpened),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.sendEmail),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00C1E8),
          ),
        ),
      );
    }

    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.posSettings,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: [
                Tab(
                  text: loc.generalSettings,
                  icon: const Icon(Icons.settings, size: 18),
                ),
                Tab(
                  text: loc.syncLogs,
                  icon: const Icon(Icons.sync, size: 18),
                ),
                Tab(
                  text: loc.advancedSettings,
                  icon: const Icon(Icons.tune, size: 18),
                ),
                Tab(
                  text: loc.help,
                  icon: const Icon(Icons.help_outline, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoadingSettings
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.grey[50],
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGeneralSettingsTab(),
                  _buildSyncLogsTab(),
                  _buildAdvancedSettingsTab(),
                  _buildHelpTab(),
                ],
              ),
            ),
    );
  }

  // General settings tab (existing functionality)
  Widget _buildGeneralSettingsTab() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildConnectionStatusCard(),
          const SizedBox(height: 16),
          _buildToggleCard(),
          const SizedBox(height: 16),
          _buildSystemTypeSelector(),
          const SizedBox(height: 16),
          _buildApiConfigCard(),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
