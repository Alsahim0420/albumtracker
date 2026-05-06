import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/features/home/presentation/widgets/album_badge_flag_display.dart';
import 'package:albumtracker/features/home/presentation/widgets/team_country_filter_widgets.dart';
import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/core/storage/hive_storage.dart';
import 'package:albumtracker/features/home/presentation/bloc/album_bloc.dart';
import 'package:albumtracker/features/home/presentation/bloc/album_event.dart';

class RepeatedStickersView extends StatefulWidget {
  const RepeatedStickersView({super.key});

  @override
  State<RepeatedStickersView> createState() => _RepeatedStickersViewState();
}

class _RepeatedStickersViewState extends State<RepeatedStickersView> {
  /// null = All, otherwise country code (e.g. BRA).
  String? _selectedCountry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<Box>(
      valueListenable: collectionBox.listenable(),
      builder: (context, box, _) {
        final map = collectedStickersMap;
        final repeatedEntries =
            map.entries.where((e) => e.value > 1).toList();

        if (repeatedEntries.isEmpty) {
          return _buildEmptyState(context);
        }

        final totalDuplicates = _totalDuplicates(repeatedEntries);
        final countries = _countriesFromEntries(repeatedEntries);
        final filtered = _filterByCountry(repeatedEntries, _selectedCountry);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'homeFilterSwaps'.tr(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'homeFilterSwaps'.tr(args: [totalDuplicates.toString()]),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            _CountryFilterTrigger(
              selected: _selectedCountry,
              countries: countries,
              onSelect: (code) => setState(() => _selectedCountry = code),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const crossCount = 3;
                  const padding = 16.0;
                  const spacing = 10.0;
                  final width = (constraints.maxWidth - 2 * padding - (crossCount - 1) * spacing) / crossCount;
                  final itemHeight = width * 1.15;

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(padding, 0, padding, 88),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: width / itemHeight,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      return _RepeatedStickerCard(
                        stickerId: entry.key,
                        count: entry.value,
                        onTap: () => _openCountSheet(context, entry.key, entry.value),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _openCountSheet(BuildContext context, String stickerId, int count) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CountSheet(
        stickerId: stickerId,
        onDone: () => Navigator.of(ctx).pop(),
        onSetCount: (newCount) async {
          ctx.read<AlbumBloc>().add(
                AlbumUpdateStickerCountRequested(
                  stickerId: stickerId,
                  count: newCount,
                ),
              );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 64,
              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 20),
            Text(
              'noRepeatedStickers'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static int _totalDuplicates(List<MapEntry<String, int>> entries) {
    return entries.fold(0, (sum, e) => sum + (e.value - 1));
  }

  static List<String> _countriesFromEntries(List<MapEntry<String, int>> entries) {
    final set = <String>{};
    for (final e in entries) {
      set.add(_teamCodeFromStickerId(e.key));
    }
    final list = set.toList()
      ..sort((a, b) {
        final specialCode = WorldCup2026Seed.specialTeamCode;
        if (a == specialCode && b != specialCode) return -1;
        if (b == specialCode && a != specialCode) return 1;
        return a.compareTo(b);
      });
    return list;
  }

  static List<MapEntry<String, int>> _filterByCountry(
    List<MapEntry<String, int>> entries,
    String? countryCode,
  ) {
    if (countryCode == null) return entries;
    return entries
        .where((e) => _teamCodeFromStickerId(e.key) == countryCode)
        .toList();
  }

  static String _teamCodeFromStickerId(String stickerId) {
    final idx = stickerId.indexOf('-');
    return idx > 0 ? stickerId.substring(0, idx) : stickerId;
  }
}

class _CountryFilterTrigger extends StatelessWidget {
  const _CountryFilterTrigger({
    required this.selected,
    required this.countries,
    required this.onSelect,
  });

  final String? selected;
  final List<String> countries;
  final void Function(String?) onSelect;

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterSheet(
        selected: selected,
        countries: countries,
        onSelect: (code) {
          Navigator.of(ctx).pop();
          onSelect(code);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openFilterSheet(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 22,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TeamCountryFilterBarContent(
                    selectedTeamCode: selected,
                    textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 24,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.selected,
    required this.countries,
    required this.onSelect,
  });

  final String? selected;
  final List<String> countries;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.6;
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'filterByCountry'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FilterListTile(
                      label: 'homeFilterAll'.tr(),
                      isSelected: selected == null,
                      onTap: () => onSelect(null),
                    ),
                    ...countries.map(
                      (code) => TeamCountryFilterSheetTile(
                        teamCode: code,
                        isSelected: selected == code,
                        onTap: () => onSelect(code),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterListTile extends StatelessWidget {
  const _FilterListTile({
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                size: 22,
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subtítulo en tarjeta (no badge): PL-* muestra el número global; resto tipo de lámina.
String _stickerSubtitleFromId(String stickerId) {
  if (WorldCup2026Seed.isPlayerStickerId(stickerId)) {
    return WorldCup2026Seed.stickerNumberLabel(stickerId);
  }
  if (WorldCup2026Seed.isBadgeStickerId(stickerId)) return 'badge'.tr();
  if (WorldCup2026Seed.getStickerById(stickerId)?.type == StickerType.team_photo) {
    return 'photo'.tr();
  }
  return 'sticker'.tr();
}

class _RepeatedStickerCard extends StatelessWidget {
  const _RepeatedStickerCard({
    required this.stickerId,
    required this.count,
    required this.onTap,
  });

  final String stickerId;
  final int count;
  final VoidCallback onTap;

  int get _duplicateCount => count - 1;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isBadge = WorldCup2026Seed.isBadgeStickerId(stickerId);
    final flagPath = isBadge ? albumBadgeFlagAssetPathForStickerId(stickerId) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (isBadge)
                    _RepeatedBadgeHeader(stickerId: stickerId, colors: colors)
                  else
                    Text(
                      WorldCup2026Seed.stickerCaptionTitle(stickerId),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurface,
                            fontSize: WorldCup2026Seed.isPlayerStickerId(stickerId) ? 11 : 10,
                            fontFamily: WorldCup2026Seed.isPlayerStickerId(stickerId) ? null : 'monospace',
                            fontWeight: WorldCup2026Seed.isPlayerStickerId(stickerId) ? FontWeight.w600 : null,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: isBadge ? 8 : 6),
                  if (isBadge && flagPath != null)
                    Expanded(
                      child: _repeatedBadgeFlagWithCode(context, stickerId, flagPath, colors),
                    )
                  else if (isBadge)
                    Expanded(
                      child: Center(
                        child: Text(
                          'noShieldAvailable'.tr(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 10,
                              ),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Text(
                      _stickerSubtitleFromId(stickerId),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFamily: WorldCup2026Seed.isPlayerStickerId(stickerId) ? 'monospace' : null,
                          ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$_duplicateCount',
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountSheet extends StatelessWidget {
  const _CountSheet({
    required this.stickerId,
    required this.onDone,
    required this.onSetCount,
  });

  final String stickerId;
  final VoidCallback onDone;
  final Future<void> Function(int newCount) onSetCount;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: collectionBox.listenable(),
      builder: (context, box, _) {
        final count = collectedStickersMap[stickerId] ?? 0;
        final duplicateCount = count > 1 ? count - 1 : 0;
        final colors = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                WorldCup2026Seed.stickerCaptionTitle(stickerId),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                _stickerSubtitleFromId(stickerId),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFamily: WorldCup2026Seed.isPlayerStickerId(stickerId) ? 'monospace' : null,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SheetButton(
                    icon: Icons.remove_rounded,
                    onPressed: count <= 1
                        ? null
                        : () async {
                            await onSetCount(count - 1);
                            if (context.mounted && (count - 1) <= 1) onDone();
                          },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '$duplicateCount',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                    ),
                  ),
                  _SheetButton(
                    icon: Icons.add_rounded,
                    onPressed: () async {
                      await onSetCount(count + 1);
                      if (context.mounted) {
                        final sticker = WorldCup2026Seed.getStickerById(stickerId);
                        if (sticker != null) {
                          final team = sticker.teamId;
                          final line = switch (sticker.type) {
                            StickerType.badge => 'Insignia - $team',
                            StickerType.team_photo => 'Foto de equipo - $team',
                            StickerType.player =>
                              ((sticker.playerName ?? '').trim().isNotEmpty)
                                  ? '${sticker.playerName!.trim()} - $team'
                                  : 'Jugador - $team',
                            StickerType.special => 'Especial - ${sticker.displayCode}',
                          };
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Agregadas:\n$line'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RepeatedBadgeHeader extends StatelessWidget {
  const _RepeatedBadgeHeader({
    required this.stickerId,
    required this.colors,
  });

  final String stickerId;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final s = WorldCup2026Seed.getStickerById(stickerId);
    final team = s != null ? WorldCup2026Seed.getTeamById(s.teamId) : null;
    final title = team != null
        ? 'teamDetailTeamBadgeCountry'.tr(namedArgs: {'country': team.name.tr()})
        : 'teamDetailTeamBadge'.tr();
    return Text(
      title,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

Widget _repeatedBadgeFlagWithCode(
  BuildContext context,
  String stickerId,
  String flagPath,
  ColorScheme colors,
) {
  final s = WorldCup2026Seed.getStickerById(stickerId);
  final code = s?.displayCode ?? WorldCup2026Seed.stickerNumberLabel(stickerId);
  return AlbumBadgeFlagWithCenteredCode(
    assetPath: flagPath,
    code: code,
    codeStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w500,
          fontFamily: 'monospace',
          fontSize: 12,
          letterSpacing: 0.4,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
            ),
          ],
        ) ??
        TextStyle(
          color: colors.onSurface,
          fontWeight: FontWeight.w500,
          fontFamily: 'monospace',
          fontSize: 12,
          letterSpacing: 0.4,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
            ),
          ],
        ),
  );
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: onPressed != null
                ? colors.primary.withValues(alpha: 0.2)
                : colors.outlineVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 28,
            color: onPressed != null ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
