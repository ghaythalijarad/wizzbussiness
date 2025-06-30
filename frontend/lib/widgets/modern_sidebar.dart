import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../services/language_service.dart';

class ModernSidebar extends StatefulWidget {
  final bool isOnline;
  final Function(bool) onToggleStatus;
  final VoidCallback onReturnOrder;
  final Function(int) onNavigate;
  final VoidCallback onClose;
  final Function(Locale)? onLanguageChanged;

  const ModernSidebar({
    super.key,
    required this.isOnline,
    required this.onToggleStatus,
    required this.onReturnOrder,
    required this.onNavigate,
    required this.onClose,
    this.onLanguageChanged,
  });

  @override
  State<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<ModernSidebar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _rippleController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

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
    super.dispose();
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
                              topRight: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 30,
                                offset: const Offset(5, 0),
                                spreadRadius: 5,
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
          // Modern header with gradient
          _buildModernHeader(context, localizations, colorScheme),

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

  Widget _buildModernHeader(BuildContext context,
      AppLocalizations localizations, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          // App icon with modern design
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.dashboard_customize_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.businessManagement,
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  localizations.dashboard,
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Modern close button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _closeWithAnimation,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, AppLocalizations localizations,
      ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Status indicator with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isOnline
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: widget.isOnline ? Colors.green : Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isOnline
                          ? localizations.online
                          : localizations.offline,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.isOnline
                          ? localizations.readyToReceiveOrders
                          : localizations.ordersArePaused,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Modern toggle switch
              Switch.adaptive(
                value: widget.isOnline,
                onChanged: widget.onToggleStatus,
                activeColor: Colors.green,
                inactiveThumbColor: Colors.orange,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenu(BuildContext context,
      AppLocalizations localizations, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        const SizedBox(height: 8),

        // Main navigation items
        _buildModernMenuItem(
          context: context,
          icon: Icons.shopping_bag_rounded,
          title: localizations.orders,
          subtitle: 'Manage your orders',
          onTap: () => _navigateAndClose(0),
          colorScheme: colorScheme,
        ),

        _buildModernMenuItem(
          context: context,
          icon: Icons.inventory_2_rounded,
          title: localizations.items,
          subtitle: localizations.menuItemsAndCategories,
          onTap: () => _navigateAndClose(1),
          colorScheme: colorScheme,
        ),

        _buildModernMenuItem(
          context: context,
          icon: Icons.analytics_rounded,
          title: localizations.analytics,
          subtitle: localizations.businessInsights,
          onTap: () => _navigateAndClose(2),
          colorScheme: colorScheme,
        ),

        _buildModernMenuItem(
          context: context,
          icon: Icons.local_offer_rounded,
          title: localizations.discounts,
          subtitle: localizations.offersAndPromotions,
          onTap: () => _navigateAndClose(3),
          colorScheme: colorScheme,
        ),

        _buildModernMenuItem(
          context: context,
          icon: Icons.settings_rounded,
          title: localizations.settings,
          subtitle: localizations.appConfiguration,
          onTap: () => _navigateAndClose(4),
          colorScheme: colorScheme,
        ),

        const SizedBox(height: 16),

        // Divider with label
        Row(
          children: [
            Expanded(
                child: Divider(color: colorScheme.outline.withOpacity(0.2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                localizations.quickActions,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
                child: Divider(color: colorScheme.outline.withOpacity(0.2))),
          ],
        ),

        const SizedBox(height: 16),

        // Quick action items
        _buildModernMenuItem(
          context: context,
          icon: Icons.language_rounded,
          title: localizations.language,
          subtitle: localizations.changeAppLanguage,
          onTap: () => _showLanguageDialog(context),
          colorScheme: colorScheme,
        ),

        _buildModernMenuItem(
          context: context,
          icon: Icons.undo_rounded,
          title: localizations.returnOrder,
          subtitle: localizations.cancelRecentOrder,
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

  Widget _buildModernMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon with background
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withOpacity(0.1)
                        : colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? Colors.red : colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDestructive
                              ? Colors.red
                              : colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow indicator
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colorScheme.onSurface.withOpacity(0.4),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFooter(BuildContext context,
      AppLocalizations localizations, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: colorScheme.onSurface.withOpacity(0.6),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              localizations.tapOutsideOrPressEscToClose,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
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
