import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:albumtracker/core/data/shield_assets.dart';
import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/features/home/presentation/models/team_sticker_item.dart';
import 'package:albumtracker/features/home/presentation/widgets/album_badge_flag_display.dart';

/// Card de una lamina en la rejilla del equipo (encontrada o faltante).
class TeamStickerCard extends StatelessWidget {
  const TeamStickerCard({
    super.key,
    required this.sticker,
    this.count,
    this.onTap,
    /// Bandera del [TeamModel] (detalle equipo). Si es null en insignia, se resuelve por código.
    this.teamFlagAssetPath,
  });

  final TeamStickerItem sticker;
  /// Si se pasa, se usa para mostrar estado y cantidad (count > 0 = encontrada).
  final int? count;
  final VoidCallback? onTap;
  final String? teamFlagAssetPath;

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
              padding: EdgeInsets.fromLTRB(
                10,
                10,
                _trailingPaddingForCard(sticker.type, count),
                10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (sticker.type != TeamStickerType.badge) ...[
                    Text(
                      'stickerId'.tr(args: [
                        _headerCode(sticker),
                      ]),
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
                  ],
                  Expanded(
                    child: _buildCenterContent(context, isCollected, count),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: _buildCornerStatus(context, colors, isCollected),
            ),
          ],
        ),
      ),
    );
  }

  double _trailingPaddingForCard(TeamStickerType type, int? count) {
    if (type == TeamStickerType.badge && count != null && count > 1) {
      return 10;
    }
    return 20;
  }

  Widget _buildCornerStatus(BuildContext context, ColorScheme colors, bool isCollected) {
    if (!isCollected) {
      return Icon(
        Icons.circle_outlined,
        color: colors.onSurfaceVariant.withValues(alpha: 0.6),
        size: 20,
      );
    }
    final n = count;
    if (n != null && n > 1 && sticker.type == TeamStickerType.badge) {
      return const SizedBox.shrink();
    }
    if (n != null && n > 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$n',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Icon(Icons.check_circle, color: colors.onSurface, size: 20);
  }

  Widget _duplicateChip(BuildContext context, ColorScheme colors, int n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$n',
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String? _resolveBadgeFlagPath() {
    final fromProp = teamFlagAssetPath?.trim();
    if (fromProp != null && fromProp.isNotEmpty) return fromProp;
    final sm = WorldCup2026Seed.getStickerByFlexibleIdentifier(sticker.code);
    if (sm != null) {
      final team = WorldCup2026Seed.getTeamById(sm.teamId);
      final p = team?.flagAssetPath?.trim();
      if (p != null && p.isNotEmpty) return p;
      return getShieldAssetPath(sm.teamId);
    }
    final parts = sticker.displayCode.split(RegExp(r'\s+'));
    if (parts.isNotEmpty) {
      return getShieldAssetPath(parts.first);
    }
    return null;
  }

  String _badgeTitleText(BuildContext context) {
    final sm = WorldCup2026Seed.getStickerByFlexibleIdentifier(sticker.code);
    if (sm != null) {
      final team = WorldCup2026Seed.getTeamById(sm.teamId);
      if (team != null) {
        return 'teamDetailTeamBadgeCountry'.tr(
          namedArgs: {'country': team.name.tr()},
        );
      }
    }
    return 'teamDetailTeamBadge'.tr();
  }

  Widget _buildCenterContent(BuildContext context, bool isCollected, int? count) {
    final colors = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isCollected ? colors.onPrimary : colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        );
    if (sticker.type == TeamStickerType.badge) {
      final shieldPath = _resolveBadgeFlagPath();
      if (shieldPath != null) {
        final codeColor = isCollected ? colors.onPrimary : colors.onSurface;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: AlbumBadgeFlagWithCenteredCode(
                assetPath: shieldPath,
                code: sticker.displayCode,
                codeStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: codeColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      letterSpacing: 0.4,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: isCollected ? 0.3 : 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ) ??
                    TextStyle(
                      color: codeColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      letterSpacing: 0.4,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: isCollected ? 0.3 : 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _badgeTitleText(context),
                    style: textStyle?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isCollected ? colors.onPrimary : colors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (count != null && count > 1) ...[
                  const SizedBox(width: 6),
                  _duplicateChip(context, colors, count),
                ],
              ],
            ),
          ],
        );
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 28, color: colors.onSurfaceVariant),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'noShieldAvailable'.tr(),
                  style: textStyle?.copyWith(fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (count != null && count > 1) ...[
                const SizedBox(width: 6),
                _duplicateChip(context, colors, count),
              ],
            ],
          ),
        ],
      );
    }
    final IconData icon;
    switch (sticker.type) {
      case TeamStickerType.photo:
        icon = Icons.groups_2_rounded;
        break;
      case TeamStickerType.player:
        icon = Icons.person_outline;
        break;
      default:
        icon = Icons.star;
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
            sticker.type == TeamStickerType.player
                ? (sticker.name ?? sticker.label)
                : (sticker.name?.tr() ?? sticker.label.tr()),
            style: textStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _headerCode(TeamStickerItem item) {
    if (item.type != TeamStickerType.badge) return item.displayCode;
    final parts = item.displayCode.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : item.displayCode;
  }
}
