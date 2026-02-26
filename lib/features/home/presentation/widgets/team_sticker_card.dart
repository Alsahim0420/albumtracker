import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:albumtracker/features/home/presentation/models/team_sticker_item.dart';

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
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isCollected ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isCollected
              ? null
              : Border.all(color: colors.outlineVariant, width: 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    'stickerId'.tr(args: [sticker.code]),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isCollected
                              ? colors.onPrimary.withValues(alpha: 0.9)
                              : colors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: _buildCenterContent(context, isCollected),
                  ),
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
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$count',
                            style:TextStyle(
                              color: colors.onSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : Icon(Icons.check_circle, color: colors.onSurface, size: 20)
                  : Icon(
                      Icons.circle_outlined,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                      size: 20,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterContent(BuildContext context, bool isCollected) {
    final colors = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isCollected ? colors.onPrimary : colors.onSurfaceVariant,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(
            'teamDetailTeamPhoto'.tr(),
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'teamDetailNotFound'.tr(),
            style: textStyle?.copyWith(
              fontSize: 10,
              color: colors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
            color: isCollected ? colors.onPrimary : colors.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            sticker.name?.tr() ?? sticker.label.tr(),
            style: textStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
