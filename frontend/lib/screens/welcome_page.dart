import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'login_page.dart';
import 'registration_form_screen.dart';

class WelcomePage extends StatelessWidget {
  final Function(Locale) onLanguageChanged;

  const WelcomePage({Key? key, required this.onLanguageChanged})
      : super(key: key);

  void _showLanguageDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(loc.selectLanguage),
        children: [
          SimpleDialogOption(
            onPressed: () {
              onLanguageChanged(const Locale('en'));
              Navigator.pop(context);
            },
            child: Row(
              children: [
                const Text('🇺🇸'),
                const SizedBox(width: 8),
                Text(loc.english)
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              onLanguageChanged(const Locale('ar'));
              Navigator.pop(context);
            },
            child: Row(
              children: [
                const Text('🇸🇦'),
                const SizedBox(width: 8),
                Text(loc.arabic)
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
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
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => _showLanguageDialog(context),
            icon: const Icon(Icons.language),
            tooltip: loc.language,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              Text(loc.welcomeToOrderReceiver,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(loc.welcomeDescription,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        LoginPage(onLanguageChanged: onLanguageChanged),
                  ),
                ),
                child: Text(loc.getStarted),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegistrationFormScreen(),
                  ),
                ),
                child: Text(loc.testRegistrationForm),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
