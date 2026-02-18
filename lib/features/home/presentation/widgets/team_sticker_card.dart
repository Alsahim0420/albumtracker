import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/team_sticker_item.dart';

/// Card de una pegatina en la rejilla del equipo (encontrada o faltante).
class TeamStickerCard extends StatelessWidget {
  const TeamStickerCard({
    super.key,
    required this.sticker,
    this.count,
    this.onTap,
  });

  final TeamStickerItem sticker;
  /// Si se pasa, se usa para mostrar estado y cantidad (count > 0 = encontrada).
  final int? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCollected = count != null ? (count! > 0) : sticker.collected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isCollected ? AppColors.primary : AppColors.itemMissing,
          borderRadius: BorderRadius.circular(12),
          border: isCollected
              ? null
              : Border.all(color: AppColors.inputBorder, width: 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sticker.code,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isCollected
                              ? AppColors.textPrimary.withValues(alpha: 0.9)
                              : AppColors.textSecondary,
                          fontSize: 11,
                        ),
                  ),
                  const SizedBox(height: 6),
                  _buildCenterContent(context, isCollected),
                ],
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: isCollected
                  ? (count != null && count! > 1)
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.swapGreenDark,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : const Icon(Icons.check_circle, color: AppColors.textPrimary, size: 20)
                  : Icon(
                      Icons.circle_outlined,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                      size: 20,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterContent(BuildContext context, bool isCollected) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isCollected ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        );
    final IconData icon;
    switch (sticker.type) {
      case TeamStickerType.badge:
        icon = Icons.star;
        break;
      case TeamStickerType.photo:
        icon = Icons.people_outline;
        break;
      case TeamStickerType.player:
        icon = Icons.person_outline;
        break;
    }
    if (sticker.type == TeamStickerType.photo && !sticker.collected) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(AppConstants.teamDetailTeamPhoto, style: textStyle),
          Text(
            AppConstants.teamDetailNotFound,
            style: textStyle?.copyWith(
              fontSize: 10,
              color: AppColors.placeholder,
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isCollected ? AppColors.textPrimary : AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            sticker.name ?? sticker.label,
            style: textStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
