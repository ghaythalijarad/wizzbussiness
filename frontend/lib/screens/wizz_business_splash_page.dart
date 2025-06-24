import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../screens/login_page.dart';

/// Extracted WizzBusinessSplashPage from main.dart
class WizzBusinessSplashPage extends StatefulWidget {
  final Function(Locale) onLanguageChanged;

  const WizzBusinessSplashPage({Key? key, required this.onLanguageChanged})
      : super(key: key);

  @override
  State<WizzBusinessSplashPage> createState() => _WizzBusinessSplashPageState();
}

class _WizzBusinessSplashPageState extends State<WizzBusinessSplashPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _checkAuthentication();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    // Simulate a delay for splash screen
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      final authProvider = Provider.of<Auth>(context, listen: false);
      // Navigate directly to LoginPage regardless of auth status
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) =>
                LoginPage(onLanguageChanged: widget.onLanguageChanged)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    // UI rendering logic for splash page
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _logoFadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loc.welcome,
                  style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}
