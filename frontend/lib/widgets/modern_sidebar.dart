import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/language_service.dart';
import '../services/app_state.dart';

class ModernSidebar extends ConsumerStatefulWidget {
  final bool isOnline;
  final Future<void> Function(bool) onToggleStatus;
  final VoidCallback onReturnOrder;
  final Function(int) onNavigate;
  final VoidCallback onClose;

  const ModernSidebar({
    super.key,
    required this.isOnline,
    required this.onToggleStatus,
    required this.onReturnOrder,
    required this.onNavigate,
    required this.onClose,
  });

  @override
  ConsumerState<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends ConsumerState<ModernSidebar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _rippleController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);

    // Main slide animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    // Ripple animation for interactions
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rippleController.dispose();
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _closeWithAnimation() async {
    await _animationController.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _closeWithAnimation,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              _closeWithAnimation();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Stack(
            children: [
              // Animated backdrop
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Container(
                    color: Colors.black
                        .withValues(alpha: _fadeAnimation.value * 0.5),
                  );
                },
              ),
              // Main sidebar
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _slideAnimation.value *
                          MediaQuery.of(context).size.width *
                          0.8,
                      0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          height: MediaQuery.of(context).size.height,
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(2, 0),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: GestureDetector(
                              onTap:
                                  () {}, // Prevent closing when tapping sidebar
                              child: _buildSidebarContent(
                                  context, localizations, colorScheme),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarContent(BuildContext context,
      AppLocalizations localizations, ColorScheme colorScheme) {
    return SafeArea(
      child: Column(
        children: [
          // Status card with glassmorphism effect
          _buildStatusCard(context, localizations, colorScheme),

          // Navigation menu
          Expanded(
            child: _buildNavigationMenu(context, localizations, colorScheme),
          ),

          // Modern footer
          _buildModernFooter(context, localizations, colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, AppLocalizations localizations,
      ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Simple status indicator
          Icon(
            _appState.isOnline ? Icons.wifi : Icons.wifi_off,
            color: _appState.isOnline
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              _appState.isOnline ? localizations.online : localizations.offline,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),

          // Loading indicator or toggle switch
          _appState.isToggling
              ? SizedBox(
                  width: 48,
                  height: 28,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _appState.isOnline
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                )
              : Switch.adaptive(
                  value: _appState.isOnline,
                  onChanged: _appState.isToggling
                      ? null
                      : (value) async {
                          try {
                            await _appState.setOnline(
                                value, widget.onToggleStatus);
                          } catch (error) {
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
                        },
                  activeColor: Colors.green.shade700,
                  activeTrackColor: Colors.green.shade300,
                  inactiveThumbColor: Colors.red.shade700,
                  inactiveTrackColor: Colors.red.shade300,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenu(BuildContext context,
      AppLocalizations localizations, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Main navigation items
        _buildMenuItem(
          context: context,
          icon: Icons.shopping_bag,
          title: localizations.orders,
          onTap: () => _navigateAndClose(0),
          colorScheme: colorScheme,
        ),

        _buildMenuItem(
          context: context,
          icon: Icons.inventory_2,
          title: localizations.items,
          onTap: () => _navigateAndClose(1),
          colorScheme: colorScheme,
        ),

        _buildMenuItem(
          context: context,
          icon: Icons.analytics,
          title: localizations.analytics,
          onTap: () => _navigateAndClose(2),
          colorScheme: colorScheme,
        ),

        _buildMenuItem(
          context: context,
          icon: Icons.local_offer,
          title: localizations.discounts,
          onTap: () => _navigateAndClose(3),
          colorScheme: colorScheme,
        ),

        _buildMenuItem(
          context: context,
          icon: Icons.settings,
          title: localizations.settings,
          onTap: () => _navigateAndClose(4),
          colorScheme: colorScheme,
        ),

        const SizedBox(height: 8),
        Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
        const SizedBox(height: 8),

        // Quick action items
        _buildMenuItem(
          context: context,
          icon: Icons.language,
          title: localizations.language,
          onTap: () => _showLanguageDialog(context),
          colorScheme: colorScheme,
        ),

        _buildMenuItem(
          context: context,
          icon: Icons.undo,
          title: localizations.returnOrder,
          onTap: () {
            widget.onReturnOrder();
            _closeWithAnimation();
          },
          colorScheme: colorScheme,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : colorScheme.onSurface,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildModernFooter(BuildContext context,
      AppLocalizations localizations, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        localizations.tapOutsideOrPressEscToClose,
        style: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.6),
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _navigateAndClose(int index) {
    widget.onNavigate(index);
    _closeWithAnimation();
  }

  void _showLanguageDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.language_rounded,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.selectLanguage,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageTile(
                context: context,
                flag: '🇺🇸',
                name: localizations.english,
                locale: const Locale('en'),
              ),
              const Divider(height: 1),
              _buildLanguageTile(
                context: context,
                flag: '🇸🇦',
                name: localizations.arabic,
                locale: const Locale('ar'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                localizations.cancel,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
    final localizations = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);
    final isSelected = currentLocale.languageCode == locale.languageCode;

    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
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
                    ? localizations.languageChangedToArabic
                    : localizations.languageChangedToEnglish,
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
    );
  }
}
