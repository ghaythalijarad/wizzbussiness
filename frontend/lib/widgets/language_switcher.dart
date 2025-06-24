import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';

class LanguageSwitcher extends StatelessWidget {
  final Function(Locale)? onLanguageChanged;
  final bool showAsIcon;
  final bool showCurrentLanguage;

  const LanguageSwitcher({
    super.key,
    this.onLanguageChanged,
    this.showAsIcon = true,
    this.showCurrentLanguage = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showAsIcon) {
      return IconButton(
        onPressed: () => _showLanguageDialog(context),
        icon: const Icon(Icons.language),
        tooltip: AppLocalizations.of(context)?.language ?? 'Language',
      );
    } else {
      return TextButton.icon(
        onPressed: () => _showLanguageDialog(context),
        icon: const Icon(Icons.language, color: Color(0xFF00C1E8), size: 20),
        label: Text(
          showCurrentLanguage
              ? _getCurrentLanguageName(context)
              : AppLocalizations.of(context)?.language ?? 'Language',
          style: const TextStyle(color: Color(0xFF00C1E8)),
        ),
      );
    }
  }

  String _getCurrentLanguageName(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final loc = AppLocalizations.of(context)!;
    switch (locale.languageCode) {
      case 'ar':
        return loc.arabic;
      case 'en':
      default:
        return loc.english;
    }
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
                AppLocalizations.of(context)?.selectLanguage ??
                    'Select Language',
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
                AppLocalizations.of(context)?.cancel ?? 'Cancel',
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
      onTap: () {
        if (onLanguageChanged != null) {
          onLanguageChanged!(locale);
        }
        Navigator.of(context).pop();
      },
    );
  }
}

class LanguageDropdown extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;

  const LanguageDropdown({
    super.key,
    this.onLanguageChanged,
  });

  @override
  State<LanguageDropdown> createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown> {
  String _selectedLanguage = 'ar'; // Default to Arabic

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final languageCode = await LanguageService.getLanguage();
    setState(() {
      _selectedLanguage = languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      child: DropdownButton<String>(
        value: _selectedLanguage,
        icon: const Icon(Icons.language),
        hint: Text(AppLocalizations.of(context)?.language ?? 'Language'),
        underline: const SizedBox(), // Remove underline
        items: LanguageService.getAvailableLanguages().map((language) {
          return DropdownMenuItem<String>(
            value: language['code'],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_getFlagForLanguage(language['code']!),
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(language['nativeName']!,
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedLanguage = newValue;
            });

            final locale = LanguageService.getLocaleFromLanguageCode(newValue);
            if (widget.onLanguageChanged != null) {
              widget.onLanguageChanged!(locale);
            }
          }
        },
      ),
    );
  }

  String _getFlagForLanguage(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return '🇸🇦';
      case 'en':
      default:
        return '🇺🇸';
    }
  }
}
