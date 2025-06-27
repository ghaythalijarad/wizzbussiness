import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';

class SimpleSidebar extends StatefulWidget {
  final bool isOnline;
  final Function(bool) onToggleStatus;
  final VoidCallback onReturnOrder;
  final Function(int) onNavigate;
  final VoidCallback onClose;
  final Function(Locale)? onLanguageChanged;

  const SimpleSidebar({
    super.key,
    required this.isOnline,
    required this.onToggleStatus,
    required this.onReturnOrder,
    required this.onNavigate,
    required this.onClose,
    this.onLanguageChanged,
  });

  @override
  State<SimpleSidebar> createState() => _SimpleSidebarState();
}

class _SimpleSidebarState extends State<SimpleSidebar> {
  late bool _isOnline;

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
                            const Expanded(
                              child: Text(
                                'Menu',
                                style: TextStyle(
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
                          color: _isOnline ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isOnline ? Colors.green.shade200 : Colors.red.shade200,
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
                                    _isOnline ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _isOnline ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                  Text(
                                    _isOnline ? 'Ready for orders' : 'Orders paused',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isOnline,
                              onChanged: (value) {
                                setState(() {
                                  _isOnline = value;
                                });
                                widget.onToggleStatus(value);
                              },
                              activeColor: Colors.white,
                              activeTrackColor: Colors.green,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: Colors.red.shade300,
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
                              title: 'Dashboard',
                              onTap: () {
                                widget.onNavigate(0);
                                widget.onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.inventory_2,
                              title: 'Items',
                              onTap: () {
                                widget.onNavigate(1);
                                widget.onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.analytics,
                              title: 'Analytics',
                              onTap: () {
                                widget.onNavigate(2);
                                widget.onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.local_offer,
                              title: 'Discounts',
                              onTap: () {
                                widget.onNavigate(3);
                                widget.onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.settings,
                              title: 'Settings',
                              onTap: () {
                                widget.onNavigate(4);
                                widget.onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.language,
                              title: 'Language',
                              onTap: () {
                                _showLanguageDialog(context);
                              },
                            ),
                            const Divider(height: 32),
                            _buildMenuItem(
                              icon: Icons.undo,
                              title: 'Return Order',
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
                                'Tap outside to close',
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
                loc.selectLanguage,
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
                name: loc.english,
                locale: const Locale('en'),
              ),
              const Divider(height: 1),
              _buildLanguageTile(
                context: context,
                flag: '🇸🇦',
                name: loc.arabic,
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
        if (widget.onLanguageChanged != null) {
          widget.onLanguageChanged!(locale);
        }

        // Save the language preference
        await LanguageService.setLanguage(locale.languageCode);

        Navigator.of(context).pop();

        // Show confirmation
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                locale.languageCode == 'ar'
                    ? 'تم تغيير اللغة إلى العربية'
                    : 'Language changed to English',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }
}
