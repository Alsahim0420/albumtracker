// ignore_for_file: unnecessary_underscores, unused_import

import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:albumtracker/main.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../home/presentation/widgets/flag_placeholder.dart';
import '../../../../core/repository/album_repository.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/settings_profile_card.dart';
import '../widgets/settings_section.dart';

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
    final userName = storedUserName ?? 'Collector';
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
                  AppConstants.settingsTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28, color: colors.onSurface),
                ),
              ),
              SettingsProfileCard(
                userName: userName,
                avatarColor: avatarColor,
                collected: s.collectedStickers,
                total: s.totalStickers,
                onEdit: () {},
              ),
              SettingsSectionHeader(title: AppConstants.settingsAccount),
              SettingsTile(
                icon: Icons.person_outline,
                title: AppConstants.settingsAccountSettings,
                onTap: () {},
              ),
              SettingsTile(
                icon: Icons.notifications_outlined,
                title: AppConstants.settingsNotifications,
                trailing: Text(
                  AppConstants.settingsNotificationsOn,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurface),
                ),
                onTap: () {},
              ),
              SettingsTile(
                icon: Icons.shield_outlined,
                title: AppConstants.settingsPrivacySecurity,
                onTap: () {},
              ),
              SettingsSectionHeader(title: AppConstants.settingsCollectionData),
              SettingsTile(
                icon: Icons.download_outlined,
                title: AppConstants.settingsExportData,
                onTap: () {},
              ),
              SettingsSectionHeader(title: AppConstants.settingsSupport),
              SettingsTile(
                icon: Icons.info_outline_rounded,
                title: AppConstants.settingsAppInformation,
                onTap: () {},
              ),
              SettingsTile(
                icon: Icons.help_outline_rounded,
                title: AppConstants.settingsHelpFaq,
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