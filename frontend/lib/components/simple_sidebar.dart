import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/session_provider.dart';
import '../services/language_service.dart';
import '../screens/merchant_online_status_screen.dart';

class SimpleSidebar extends ConsumerStatefulWidget {
  final bool isOnline;
  final Function(bool) onToggleStatus;
  final VoidCallback onReturnOrder;
  final Function(int) onNavigate;
  final VoidCallback onClose;

  const SimpleSidebar({
    super.key,
    required this.isOnline,
    required this.onToggleStatus,
    required this.onReturnOrder,
    required this.onNavigate,
    required this.onClose,
  });

  @override
  ConsumerState<SimpleSidebar> createState() => _SimpleSidebarState();
}

class _SimpleSidebarState extends ConsumerState<SimpleSidebar> {
  late bool _isOnline;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _isOnline = widget.isOnline;
  }

  @override
  void didUpdateWidget(SimpleSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOnline != widget.isOnline) {
      _isOnline = widget.isOnline;
    }
  }

  Future<void> _handleToggleStatus(bool value) async {
    if (_isToggling) return; // Prevent multiple simultaneous toggles

    setState(() {
      _isToggling = true;
    });

    try {
      await widget.onToggleStatus(value);
      // Only update the state if the operation succeeds
      setState(() {
        _isOnline = value;
        _isToggling = false;
      });
    } catch (error) {
      // Revert the switch state if the operation fails
      setState(() {
        _isToggling = false;
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update status. Please try again.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background overlay
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            color: Colors.black54,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // Sidebar
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping sidebar
            child: Material(
              elevation: 8,
              child: Container(
                width: 300,
                height: double.infinity,
                color: Colors.white,
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        color: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.menu,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: widget.onClose,
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status section
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isOnline
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isOnline
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isOnline ? Icons.wifi : Icons.wifi_off,
                              color: _isOnline ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isOnline
                                        ? AppLocalizations.of(context)!.online
                                        : AppLocalizations.of(context)!.offline,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _isOnline
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                  Text(
                                    _isOnline
                                        ? AppLocalizations.of(context)!
                                            .readyToReceiveOrders
                                        : AppLocalizations.of(context)!
                                            .ordersArePaused,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _isToggling
                                ? SizedBox(
                                    width: 48,
                                    height: 28,
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            _isOnline
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Switch(
                                    value: _isOnline,
                                    onChanged: _isToggling
                                        ? null
                                        : _handleToggleStatus,
                                    activeColor: Colors.green.shade700,
                                    activeTrackColor: Colors.green.shade200,
                                    inactiveThumbColor: Colors.red.shade700,
                                    inactiveTrackColor: Colors.red.shade200,
                                  ),
                          ],
                        ),
                      ),

                      // Menu items
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(8),
                          children: [
                            _buildMenuItem(
                              icon: Icons.dashboard,
                              title: AppLocalizations.of(context)!.dashboard,
                              onTap: () {
                                widget.onNavigate(0);
                                widget.onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.inventory_2,
                              title: AppLocalizations.of(context)!.items,
                              onTap: () {
                                widget.onNavigate(1);
                                widget.onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.analytics,
                              title: AppLocalizations.of(context)!.analytics,
                              onTap: () {
                                widget.onNavigate(2);
                                widget.onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.local_offer,
                              title: AppLocalizations.of(context)!.discounts,
                              onTap: () {
                                widget.onNavigate(3);
                                widget.onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.settings,
                              title: AppLocalizations.of(context)!.settings,
                              onTap: () {
                                widget.onNavigate(4);
                                widget.onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.wifi,
                              title: 'Online Status',
                              onTap: () {
                                // Navigate to online status screen
                                final session = ref.read(sessionProvider);
                                if (session.businessId != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MerchantOnlineStatusScreen(
                                        businessId: session.businessId!,
                                      ),
                                    ),
                                  );
                                }
                                widget.onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.language,
                              title: AppLocalizations.of(context)!.languageSettings,
                              onTap: () {
                                _showLanguageDialog(context);
                              },
                            ),
                            const Divider(height: 32),
                            _buildMenuItem(
                              icon: Icons.undo,
                              title: AppLocalizations.of(context)!.returnOrder,
                              onTap: () {
                                widget.onReturnOrder();
                                widget.onClose();
                              },
                              isSpecial: true,
                            ),
                          ],
                        ),
                      ),

                      // Footer
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!
                                    .tapOutsideOrPressEscToClose,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSpecial = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      elevation: 0,
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSpecial ? Colors.orange : Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSpecial ? Colors.orange : Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.language, size: 24, color: Color(0xFF00C1E8)),
              const SizedBox(width: 8),
              Text(
                loc.changeAppLanguage,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageTile(
                context: context,
                flag: '🇺🇸',
                name: 'English',
                locale: const Locale('en'),
              ),
              const Divider(height: 1),
              _buildLanguageTile(
                context: context,
                flag: '🇸🇦',
                name: 'العربية',
                locale: const Locale('ar'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                loc.cancel,
                style: const TextStyle(color: Color(0xFF00C1E8)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageTile({
    required BuildContext context,
    required String flag,
    required String name,
    required Locale locale,
  }) {
    final currentLocale = Localizations.localeOf(context);
    final isSelected = currentLocale.languageCode == locale.languageCode;

    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name),
      trailing:
          isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () async {
        // Update the locale using the provider
        ref.read(localeProvider.notifier).setLocale(locale);

        // Save the language preference
        await LanguageService.setLanguage(locale.languageCode);

        Navigator.of(context).pop();

        // Show confirmation
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                locale.languageCode == 'ar'
                    ? AppLocalizations.of(context)!.languageChangedToArabic
                    : AppLocalizations.of(context)!.languageChangedToEnglish,
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }
}
