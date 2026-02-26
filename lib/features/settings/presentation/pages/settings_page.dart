// ignore_for_file: unnecessary_underscores, unused_import

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:albumtracker/core/repository/album_repository.dart';
import 'package:albumtracker/core/storage/hive_storage.dart';
import 'package:albumtracker/core/theme/app_colors.dart';
import 'package:albumtracker/features/settings/presentation/widgets/settings_profile_card.dart';
import 'package:albumtracker/features/settings/presentation/widgets/settings_section.dart';

void _showLanguagePicker(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
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
                      color: AppColors.textPrimary,
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

  void _openTeamSelector(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      final colors = Theme.of(context).colorScheme;
      final teams = WorldCup2026Seed.groups
          .expand((g) => g.teams)
          .toList();
      return ListView(
        children: teams.map((team) {
          return ListTile(
            title: Text(team.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurface)),
            leading: team.flagAssetPath != null &&
            team.flagAssetPath!.isNotEmpty
            ? ClipOval(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: FlagPlaceholder(code: team.flagAssetPath!),
                ),
              )
            : CircleAvatar(
                backgroundColor: team.primaryColor,
                child: Text(
                  team.name.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            onTap: () async {
              await saveUserProfile(
                name: storedUserName ?? '',
                favoriteTeam: team.id,
              );

              if (!context.mounted) return;

              // Actualiza tema
              onThemeChanged(team.id);
              if (context.mounted) Navigator.pop(context);
            },
        );
      }).toList(),
    );
  });
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
                icon: Icons.person_outline,
                title: 'settingsAccountSettings',
                onTap: () {},
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
                onTap: () {},
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
                onTap: () {},
              ),
              SettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'settingsHelpFaq',
                onTap: () {},
              ),
              SettingsTile(icon: Icons.favorite_outline, title: 'Equipo favorito', onTap: () => _openTeamSelector(context)),
              
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
    return Material(
      color: AppColors.inputBackground,
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
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, size: 22, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
