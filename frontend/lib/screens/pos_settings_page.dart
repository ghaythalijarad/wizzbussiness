import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/business.dart';
import '../models/pos_settings.dart';
import '../services/api_service.dart';
import '../services/app_auth_service.dart';
import '../screens/signin_screen.dart';
import '../theme/cravevolt_theme.dart';

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
  bool _isInitializing = true;
  List<Map<String, dynamic>> _syncLogs = [];
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Add missing state for sync logs loading
  bool _isLoadingSyncLogs = false;

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
          color: CraveVoltColors.neonLime,
          size: 48,
        ),
        title: Text(
          loc.userNotLoggedIn,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: CraveVoltColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Please sign in to access POS settings',
          style: const TextStyle(
            color: CraveVoltColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => _navigateToLogin(),
            style: TextButton.styleFrom(
              backgroundColor: CraveVoltColors.neonLime,
              foregroundColor: CraveVoltColors.background,
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
        builder: (context) => const SignInScreen(
          noticeMessage: 'Please sign in to access POS settings',
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
      final logs = await apiService.getPosSyncLogs(widget.business.id);
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
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3399FF),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.posSettings),
        backgroundColor: CraveVoltColors.surface,
        foregroundColor: CraveVoltColors.textPrimary,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: CraveVoltColors.neonLime,
          unselectedLabelColor: CraveVoltColors.textSecondary,
          indicatorColor: CraveVoltColors.neonLime,
          tabs: [
            Tab(icon: const Icon(Icons.settings), text: loc.general),
            Tab(icon: const Icon(Icons.sync), text: loc.syncLogs),
            Tab(icon: const Icon(Icons.tune), text: loc.advanced),
            Tab(icon: const Icon(Icons.help), text: loc.help),
          ],
        ),
      ),
      body: _isLoadingSettings
          ? Container(
              color: CraveVoltColors.background,
              child: Center(
                child: CircularProgressIndicator(
                  color: CraveVoltColors.neonLime,
                ),
              ),
            )
          : Container(
              color: CraveVoltColors.background,
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
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard() {
    final loc = AppLocalizations.of(context)!;

    return Card(
      color: CraveVoltColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: CraveVoltColors.neonLime.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _posSettings.enabled
                        ? CraveVoltColors.neonLime.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _posSettings.enabled ? Icons.check_circle : Icons.error,
                    color: _posSettings.enabled
                        ? CraveVoltColors.neonLime
                        : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  loc.connectionStatus,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CraveVoltColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _posSettings.enabled
                  ? loc.connectionSuccessful
                  : loc.connectionFailed,
              style: TextStyle(
                color: _posSettings.enabled
                    ? CraveVoltColors.neonLime
                    : Colors.red,
                fontSize: 14,
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
      color: CraveVoltColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: CraveVoltColors.neonLime.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CraveVoltColors.neonLime.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.point_of_sale,
                    color: CraveVoltColors.neonLime,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  loc.posIntegration,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CraveVoltColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                loc.enablePosIntegration,
                style: TextStyle(color: CraveVoltColors.textPrimary),
              ),
              subtitle: Text(
                loc.enablePosIntegrationDescription,
                style: TextStyle(color: CraveVoltColors.textSecondary),
              ),
              value: _posSettings.enabled,
              activeColor: CraveVoltColors.neonLime,
              onChanged: (value) {
                setState(() {
                  _posSettings.enabled = value;
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
      color: CraveVoltColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: CraveVoltColors.neonLime.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CraveVoltColors.neonLime.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.dns,
                    color: CraveVoltColors.neonLime,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  loc.posSystemType,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CraveVoltColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PosSystemType>(
              value: _posSettings.systemType,
              decoration: InputDecoration(
                labelText: loc.selectPosSystem,
                labelStyle: TextStyle(color: CraveVoltColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CraveVoltColors.textSecondary.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CraveVoltColors.textSecondary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CraveVoltColors.neonLime,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: CraveVoltColors.background,
              ),
              dropdownColor: CraveVoltColors.surface,
              style: TextStyle(color: CraveVoltColors.textPrimary),
              items: PosSystemType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    _getPosSystemTypeName(type),
                    style: TextStyle(color: CraveVoltColors.textPrimary),
                  ),
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
      color: CraveVoltColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: CraveVoltColors.neonLime.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CraveVoltColors.neonLime.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.api,
                    color: CraveVoltColors.neonLime,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  loc.apiConfiguration,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CraveVoltColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiEndpointController,
              style: TextStyle(color: CraveVoltColors.textPrimary),
              decoration: InputDecoration(
                labelText: loc.apiEndpoint,
                labelStyle: TextStyle(color: CraveVoltColors.textSecondary),
                hintText: 'https://api.yourpos.com',
                hintStyle: TextStyle(
                    color: CraveVoltColors.textSecondary.withOpacity(0.7)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CraveVoltColors.textSecondary.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CraveVoltColors.textSecondary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CraveVoltColors.neonLime,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: CraveVoltColors.background,
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
              style: TextStyle(color: CraveVoltColors.textPrimary),
              decoration: InputDecoration(
                labelText: loc.apiKey,
                labelStyle: TextStyle(color: CraveVoltColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CraveVoltColors.textSecondary.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CraveVoltColors.textSecondary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CraveVoltColors.neonLime,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: CraveVoltColors.background,
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.visibility,
                    color: CraveVoltColors.textSecondary,
                  ),
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
              style: TextStyle(color: CraveVoltColors.textPrimary),
              decoration: InputDecoration(
                labelText: '${loc.accessToken} (${loc.optional})',
                labelStyle: TextStyle(color: CraveVoltColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CraveVoltColors.textSecondary.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CraveVoltColors.textSecondary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CraveVoltColors.neonLime,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: CraveVoltColors.background,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationIdController,
              style: TextStyle(color: CraveVoltColors.textPrimary),
              decoration: InputDecoration(
                labelText: '${loc.locationId} (${loc.optional})',
                labelStyle: TextStyle(color: CraveVoltColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CraveVoltColors.textSecondary.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CraveVoltColors.textSecondary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CraveVoltColors.neonLime,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: CraveVoltColors.background,
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
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: CraveVoltColors.background,
                    ),
                  )
                : const Icon(Icons.wifi_tethering),
            label: Text(_isTesting ? loc.testing : loc.testConnection),
            style: ElevatedButton.styleFrom(
              backgroundColor: CraveVoltColors.neonLime,
              foregroundColor: CraveVoltColors.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _savePosSettings,
            icon: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: CraveVoltColors.background,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isLoading ? loc.saving : loc.saveSettings),
            style: ElevatedButton.styleFrom(
              backgroundColor: CraveVoltColors.surface,
              foregroundColor: CraveVoltColors.textPrimary,
              side: BorderSide(
                color: CraveVoltColors.neonLime.withOpacity(0.5),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
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
                  initialValue:
                      _posSettings.maxProcessingTimeMinutes.toString(),
                  decoration: InputDecoration(
                    labelText: '${loc.syncInterval} (${loc.minutes})',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final interval = int.tryParse(value);
                    if (interval != null) {
                      _posSettings.maxProcessingTimeMinutes = interval;
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
                  loc.troubleshootingSection,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                _buildTroubleshootingItem(
                  "Connection Issues",
                  "Check your API endpoint and credentials are correct",
                ),
                _buildTroubleshootingItem(
                  "Sync Failures",
                  "Verify your POS system is online and accessible",
                ),
                _buildTroubleshootingItem(
                  "Authentication Errors",
                  "Ensure your API key and access token are valid",
                ),
                _buildTroubleshootingItem(
                  "Network Problems",
                  "Check your internet connection and firewall settings",
                ),
                _buildTroubleshootingItem(
                  "System Configuration",
                  "Contact support if problems persist",
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
              const SizedBox(height: 16),
              TextFormField(
                initialValue: 'https://your-webhook-url.com',
                decoration: InputDecoration(
                  labelText: 'Webhook URL',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Handle webhook setup confirmation
              Navigator.of(context).pop();
            },
            child: Text(loc.ok),
          ),
        ],
      ),
    );
  }

  IconData _getSyncStatusIcon(String status) {
    switch (status) {
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.help_outline;
    }
  }

  Color _getSyncStatusColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'pending':
        return Theme.of(context).colorScheme.primary;
      default:
        return Colors.grey;
    }
  }

  String _getPosSystemTypeName(PosSystemType type) {
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
        return 'Shopify POS';
      case PosSystemType.woocommerce:
        return 'WooCommerce';
    }
  }
}
