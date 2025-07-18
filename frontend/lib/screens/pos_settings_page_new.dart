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
    } catch (e) {
      setState(() => _isTesting = false);
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.connectionFailed}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadSyncLogs() async {
    setState(() => _isLoadingSyncLogs = true);

    try {
      final apiService = ApiService();
      final logs = await apiService.getPosLogs(widget.business.id);
      setState(() {
        _syncLogs = List<Map<String, dynamic>>.from(logs);
        _isLoadingSyncLogs = false;
      });
    } catch (e) {
      setState(() => _isLoadingSyncLogs = false);
      print('Failed to load sync logs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.posSettings),
          backgroundColor: const Color(0xFF00C1E8),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.posSettings),
        backgroundColor: const Color(0xFF00C1E8),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: const Icon(Icons.settings), text: loc.general),
            Tab(icon: const Icon(Icons.sync), text: loc.syncLogs),
            Tab(icon: const Icon(Icons.tune), text: loc.advanced),
            Tab(icon: const Icon(Icons.help), text: loc.help),
          ],
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
                  _posSettings.isConnected ? Icons.check_circle : Icons.error,
                  color: _posSettings.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.connectionStatus,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _posSettings.isConnected
                  ? loc.connectionSuccessful
                  : loc.connectionFailed,
              style: TextStyle(
                color: _posSettings.isConnected ? Colors.green : Colors.red,
              ),
            ),
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
            Text(
              loc.posIntegration,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(loc.enablePosIntegration),
              subtitle: Text(loc.enablePosIntegrationDescription),
              value: _posSettings.isEnabled,
              onChanged: (value) {
                setState(() {
                  _posSettings.isEnabled = value;
                });
              },
            ),
          ],
        ),
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
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PosSystemType>(
              value: _posSettings.systemType,
              decoration: InputDecoration(
                labelText: loc.selectPosSystem,
                border: const OutlineInputBorder(),
              ),
              items: PosSystemType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getPosSystemTypeName(type)),
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
            Text(
              loc.apiConfiguration,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiEndpointController,
              decoration: InputDecoration(
                labelText: loc.apiEndpoint,
                hintText: 'https://api.yourpos.com',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return loc.pleaseEnterApiEndpoint;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: loc.apiKey,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    // Toggle password visibility
                  },
                ),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return loc.pleaseEnterApiKey;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accessTokenController,
              decoration: InputDecoration(
                labelText: '${loc.accessToken} (${loc.optional})',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationIdController,
              decoration: InputDecoration(
                labelText: '${loc.locationId} (${loc.optional})',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final loc = AppLocalizations.of(context)!;

    return Column(
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
    );
  }

  Widget _buildSyncLogsTab() {
    final loc = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: _loadSyncLogs,
      child: _isLoadingSyncLogs
          ? const Center(child: CircularProgressIndicator())
          : _syncLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.sync_disabled,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loc.noSyncLogsAvailable,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _syncLogs.length,
                  itemBuilder: (context, index) {
                    final log = _syncLogs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          _getSyncStatusIcon(log['status']),
                          color: _getSyncStatusColor(log['status']),
                        ),
                        title: Text(log['operation'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log['timestamp'] ?? ''),
                            if (log['error'] != null)
                              Text(
                                log['error'],
                                style: const TextStyle(color: Colors.red),
                              ),
                          ],
                        ),
                        trailing: Text(
                          log['status'] ?? '',
                          style: TextStyle(
                            color: _getSyncStatusColor(log['status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildAdvancedSettingsTab() {
    final loc = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.syncSettings,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _posSettings.syncInterval.toString(),
                  decoration: InputDecoration(
                    labelText: '${loc.syncInterval} (${loc.minutes})',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final interval = int.tryParse(value);
                    if (interval != null) {
                      _posSettings.syncInterval = interval;
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _posSettings.retryAttempts.toString(),
                  decoration: InputDecoration(
                    labelText: loc.retryAttempts,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final attempts = int.tryParse(value);
                    if (attempts != null) {
                      _posSettings.retryAttempts = attempts;
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(loc.testMode),
                  subtitle: Text(loc.testModeDescription),
                  value: _posSettings.testMode,
                  onChanged: (value) {
                    setState(() {
                      _posSettings.testMode = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.webhookSetupTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(loc.webhookSetupDescription),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Show webhook setup dialog
                    _showWebhookSetupDialog();
                  },
                  child: Text(loc.configureWebhooks),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpTab() {
    final loc = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.troubleshootingTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                _buildTroubleshootingItem(
                  loc.troubleshootingIssue1,
                  loc.troubleshootingDescription1,
                ),
                _buildTroubleshootingItem(
                  loc.troubleshootingIssue2,
                  loc.troubleshootingDescription2,
                ),
                _buildTroubleshootingItem(
                  loc.troubleshootingIssue3,
                  loc.troubleshootingDescription3,
                ),
                _buildTroubleshootingItem(
                  loc.troubleshootingIssue4,
                  loc.troubleshootingDescription4,
                ),
                _buildTroubleshootingItem(
                  loc.troubleshootingIssue5,
                  loc.troubleshootingDescription5,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.contactSupport,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(loc.contactSupportDescription),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Handle contact support
                  },
                  icon: const Icon(Icons.contact_support),
                  label: Text(loc.contactSupport),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTroubleshootingItem(String title, String description) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(description),
        ),
      ],
    );
  }

  void _showWebhookSetupDialog() {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.webhookConfigTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loc.webhookConfigDescription),
              const SizedBox(height: 16),
              Text('1. ${loc.webhookStep1}'),
              Text('2. ${loc.webhookStep2}'),
              Text('3. ${loc.webhookStep3}'),
              Text('4. ${loc.webhookStep4}'),
              Text('5. ${loc.webhookStep5}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.close),
          ),
        ],
      ),
    );
  }

  String _getPosSystemTypeName(PosSystemType type) {
    switch (type) {
      case PosSystemType.square:
        return 'Square';
      case PosSystemType.toast:
        return 'Toast';
      case PosSystemType.clover:
        return 'Clover';
      case PosSystemType.shopify:
        return 'Shopify POS';
      case PosSystemType.lightspeed:
        return 'Lightspeed';
      case PosSystemType.revel:
        return 'Revel';
      case PosSystemType.other:
        return 'Other';
    }
  }

  IconData _getSyncStatusIcon(String? status) {
    switch (status) {
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.help;
    }
  }

  Color _getSyncStatusColor(String? status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
