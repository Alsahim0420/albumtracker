import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/settings_profile_card.dart';
import '../widgets/settings_section.dart';

/// Contenido de la pestaña Settings (sin Scaffold; se usa dentro de Home).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              AppConstants.settingsTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
            ),
          ),
          SettingsProfileCard(
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
              style: Theme.of(context).textTheme.bodySmall,
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
          SettingsTile(
            icon: Icons.sync_rounded,
            title: AppConstants.settingsSyncStatus,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.swapGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.swapGreen.withValues(alpha: 0.5)),
              ),
              child: Text(
                AppConstants.settingsSyncUpToDate,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.swapGreen,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
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
        ],
      ),
    );
  }
}
