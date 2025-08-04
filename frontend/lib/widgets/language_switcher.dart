import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

class LanguageSwitcher extends ConsumerWidget {
  final bool showAsIcon;
  final bool showCurrentLanguage;

  const LanguageSwitcher({
    super.key,
    this.showAsIcon = true,
    this.showCurrentLanguage = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (showAsIcon) {
      return IconButton(
        onPressed: () => _showLanguageDialog(context, ref),
        icon: const Icon(Icons.language),
        tooltip: AppLocalizations.of(context)?.language ?? 'Language',
      );
    } else {
      return TextButton.icon(
        onPressed: () => _showLanguageDialog(context, ref),
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

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
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
                ref: ref,
                flag: '🇺🇸',
                name: loc.english,
                locale: const Locale('en'),
              ),
              const Divider(height: 1),
              _buildLanguageTile(
                context: context,
                ref: ref,
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
    required WidgetRef ref,
    required String flag,
    required String name,
    required Locale locale,
  }) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name),
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(locale);
        Navigator.of(context).pop();
      },
    );
  }
}

class LanguageDropdown extends ConsumerStatefulWidget {
  const LanguageDropdown({
    super.key,
  });

  @override
  ConsumerState<LanguageDropdown> createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends ConsumerState<LanguageDropdown> {
  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    // Current language is now managed by the provider
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return DropdownButton<String>(
      value: locale.languageCode,
      onChanged: (String? newValue) {
        if (newValue != null) {
          ref.read(localeProvider.notifier).setLocale(Locale(newValue));
        }
      },
      items: const [
        DropdownMenuItem(
          value: 'en',
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: 'ar',
          child: Text('العربية'),
        ),
      ],
    );
  }

}
