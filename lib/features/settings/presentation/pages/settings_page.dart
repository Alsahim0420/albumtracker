// ignore_for_file: unused_local_variable, unnecessary_underscores, unused_import

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:albumtracker/core/repository/album_repository.dart';
import 'package:albumtracker/core/storage/hive_storage.dart';
import 'package:albumtracker/core/theme/app_colors.dart';
import 'package:albumtracker/features/personalization/presentation/pages/personalization_page.dart';
import 'package:albumtracker/features/settings/presentation/widgets/settings_profile_card.dart';
import 'package:albumtracker/features/settings/presentation/widgets/settings_section.dart';

void _showLanguagePicker(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surfaceContainerHighest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final ctxColors = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'settingsLanguage'.tr(),
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ctxColors.onSurface,
                    ),
              ),
              const SizedBox(height: 16),
              _LanguageOption(
                label: 'languageEnglish'.tr(),
                isSelected: ctx.locale.languageCode == 'en',
                onTap: () {
                  ctx.setLocale(const Locale('en'));
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              _LanguageOption(
                label: 'languageSpanish'.tr(),
                isSelected: ctx.locale.languageCode == 'es',
                onTap: () {
                  ctx.setLocale(const Locale('es'));
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Contenido de la pestaña Settings (sin Scaffold; se usa dentro de Home).
class SettingsPage extends StatelessWidget {
  final Function(String?) onThemeChanged;

  const SettingsPage({
    super.key,
    required this.onThemeChanged,
  });

  void _openPersonalizeExperience(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PersonalizationPage(
          showBackButton: true,
          onComplete: () => Navigator.of(context).pop(),
          onThemeChanged: onThemeChanged,
        ),
      ),
    );
  }

  static const _urlChannel = MethodChannel('com.app.albumcollect/url_launcher');

  Future<void> _openUrl(BuildContext context, String urlString) async {
    debugPrint('[Settings] _openUrl: intentando abrir "$urlString"');
    try {
      try {
        final ok = await _urlChannel.invokeMethod<bool>('openUrl', {'url': urlString});
        if (ok == true) {
          debugPrint('[Settings] _openUrl: canal nativo completado');
          return;
        }
      } on MissingPluginException {
        // En iOS/web no está el canal; usar url_launcher
      }
      final uri = Uri.parse(urlString);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('[Settings] _openUrl: launchUrl completado correctamente');
    } catch (e, stack) {
      debugPrint('[Settings] _openUrl: ERROR al abrir enlace');
      debugPrint('[Settings]   URL: $urlString');
      debugPrint('[Settings]   Tipo: ${e.runtimeType}');
      debugPrint('[Settings]   Mensaje: $e');
      debugPrint('[Settings]   Stack trace:\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = storedUserName ?? 'defaultUserName'.tr();
    final colorHex = storedProfileColorHex;
    Color? avatarColor;
    if (colorHex != null && colorHex.isNotEmpty) {
      final hex = colorHex.startsWith('#') ? colorHex.substring(1) : colorHex;
      if (hex.length >= 8) {
        avatarColor = Color(int.parse(hex, radix: 16));
      } else if (hex.length == 6) {
        avatarColor = Color(int.parse('FF$hex', radix: 16));
      }
    }
    return ValueListenableBuilder(
      valueListenable: collectionBox.listenable(),
      builder: (context, __, ___) {
        final colors = Theme.of(context).colorScheme;
        final s = AlbumRepository.getGlobalStats();
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Text(
                  'settingsTitle'.tr(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
                ),
              ),
              SettingsProfileCard(
                userName: userName,
                avatarColor: avatarColor,
                collected: s.collectedStickers,
                total: s.totalStickers,
                onEdit: () {},
              ),
              SettingsSectionHeader(title: 'settingsAccount'),
              SettingsTile(
                icon: Icons.language_rounded,
                title: 'settingsLanguage',
                trailing: Text(
                  context.locale.languageCode == 'es' ? 'languageSpanish'.tr() : 'languageEnglish'.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () => _showLanguagePicker(context),
              ),
              SettingsTile(
                icon: Icons.tune_rounded,
                title: 'personalizationPageTitle',
                onTap: () => _openPersonalizeExperience(context),
              ),
              SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'settingsNotifications',
                trailing: Text(
                  'settingsNotificationsOn'.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () {},
              ),
              SettingsTile(
                icon: Icons.shield_outlined,
                title: 'settingsPrivacySecurity',
                onTap: () => _openUrl(context, 'https://albumcollect2026.netlify.app/privacidad'),
              ),
              SettingsSectionHeader(title: 'settingsCollectionData'),
              SettingsTile(
                icon: Icons.download_outlined,
                title: 'settingsExportData',
                onTap: () {},
              ),
              SettingsSectionHeader(title: 'settingsSupport'),
              SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'settingsAppInformation',
                onTap: () => _openUrl(context, 'https://albumcollect2026.netlify.app/'),
              ),
              SettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'settingsHelpFaq',
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, size: 22, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
