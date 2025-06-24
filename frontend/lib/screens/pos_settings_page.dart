import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/business.dart';
import '../services/pos_service.dart';

class PosSettingsPage extends StatefulWidget {
  final Business business;

  const PosSettingsPage({
    Key? key,
    required this.business,
  }) : super(key: key);

  @override
  _PosSettingsPageState createState() => _PosSettingsPageState();
}

class _PosSettingsPageState extends State<PosSettingsPage> {
  late PosSettings _posSettings;
  bool _isLoading = false;
  bool _isTesting = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _apiEndpointController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _accessTokenController = TextEditingController();
  final _locationIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPosSettings();
  }

  @override
  void dispose() {
    _apiEndpointController.dispose();
    _apiKeyController.dispose();
    _accessTokenController.dispose();
    _locationIdController.dispose();
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
  }

  void _savePosSettings() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Update settings from form
    _posSettings.apiEndpoint = _apiEndpointController.text.trim();
    _posSettings.apiKey = _apiKeyController.text.trim();
    _posSettings.accessToken = _accessTokenController.text.trim().isEmpty
        ? null
        : _accessTokenController.text.trim();
    _posSettings.locationId = _locationIdController.text.trim().isEmpty
        ? null
        : _locationIdController.text.trim();

    // Save to business settings
    widget.business.updateSettings('pos', 'settings', _posSettings.toJson());

    setState(() => _isLoading = false);

    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.posSettingsUpdated),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    // Create temporary settings for testing
    final testSettings = PosSettings(
      enabled: true,
      systemType: _posSettings.systemType,
      apiEndpoint: _apiEndpointController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      accessToken: _accessTokenController.text.trim().isEmpty
          ? null
          : _accessTokenController.text.trim(),
      locationId: _locationIdController.text.trim().isEmpty
          ? null
          : _locationIdController.text.trim(),
    );

    final success = await PosService.testConnection(testSettings);

    setState(() => _isTesting = false);

    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(success ? loc.connectionSuccessful : loc.connectionFailed),
        backgroundColor: success ? Colors.green : Colors.red,
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
                backgroundColor: Colors.blue,
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.posSettings),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
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
      ),
    );
  }
}
