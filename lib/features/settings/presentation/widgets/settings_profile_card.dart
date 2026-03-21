import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:albumtracker/core/theme/app_colors.dart';

/// Card de perfil en Settings: avatar, nombre, nivel, barra de progreso.
class SettingsProfileCard extends StatelessWidget {
  const SettingsProfileCard({
    super.key,
    required this.userName,
    this.avatarColor,
    this.collectorLevel = 'settingsCollectorLevel',
    this.collected = 420,
    this.total = 650,
    this.onEdit,
  });

  final String userName;
  /// Color del avatar; si es null se usa [AppColors.profileAvatarBg].
  final Color? avatarColor;
  final String collectorLevel;
  final int collected;
  final int total;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final percent = total > 0 ? (collected / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: avatarColor ?? colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: colors.onSurface,
                  size: 32,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  'settingsCollectorLevel'.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: colors.primary.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(colors.onSurface),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$collected/$total ${'settingsStickersCollected'.tr()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, color: colors.onSurfaceVariant, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
        ],
      ),
    );
  }
}
