import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:albumtracker/core/constants/app_constants.dart';
import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/storage/hive_storage.dart';
import 'package:albumtracker/features/home/presentation/bloc/album_bloc.dart';
import 'package:albumtracker/features/home/presentation/bloc/album_event.dart';
import 'package:albumtracker/core/theme/app_colors.dart';

/// Vista de pegatinas faltantes. Misma UI/UX que RepeatedStickersView.
class MissingStickersView extends StatefulWidget {
  const MissingStickersView({super.key});

  @override
  State<MissingStickersView> createState() => _MissingStickersViewState();
}

class _MissingStickersViewState extends State<MissingStickersView> {
  String? _selectedCountry;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: collectionBox.listenable(),
      builder: (context, box, _) {
        final map = collectedStickersMap;
        final missingIds = _missingStickerIds(map);
        if (missingIds.isEmpty) {
          return _buildEmptyState(context);
        }
        final countries = _countriesFromIds(missingIds);
        final filtered = _filterByCountry(missingIds, _selectedCountry);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.homeNavMissing,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total faltantes: ${missingIds.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            _MissingCountryFilterTrigger(
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
                      final stickerId = filtered[index];
                      return _MissingStickerCard(
                        stickerId: stickerId,
                        onTap: () => _openAddSheet(context, stickerId),
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

  void _openAddSheet(BuildContext context, String stickerId) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddOneSheet(
        stickerId: stickerId,
        onAdded: () => Navigator.of(ctx).pop(),
        onMarkCollected: () async {
          ctx.read<AlbumBloc>().add(
                AlbumUpdateStickerCountRequested(
                  stickerId: stickerId,
                  count: 1,
                ),
              );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 20),
            Text(
              '¡Álbum completo!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No te faltan láminas.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static List<String> _missingStickerIds(Map<String, int> map) {
    final ids = <String>[];
    for (final id in WorldCup2026Seed.stickerById.keys) {
      if ((map[id] ?? 0) == 0) ids.add(id);
    }
    ids.sort();
    return ids;
  }

  static List<String> _countriesFromIds(List<String> ids) {
    final set = <String>{};
    for (final id in ids) {
      set.add(_teamCodeFromStickerId(id));
    }
    final list = set.toList()..sort();
    return list;
  }

  static List<String> _filterByCountry(List<String> ids, String? countryCode) {
    if (countryCode == null) return ids;
    return ids.where((id) => _teamCodeFromStickerId(id) == countryCode).toList();
  }

  static String _teamCodeFromStickerId(String stickerId) {
    final idx = stickerId.indexOf('-');
    return idx > 0 ? stickerId.substring(0, idx) : stickerId;
  }
}

String _stickerSubtitleFromId(String stickerId) {
  if (stickerId.contains('-PL-')) return 'Player';
  if (stickerId.contains('-B-')) return 'Badge';
  if (stickerId.contains('-P-')) return 'Photo';
  return 'Sticker';
}

class _MissingCountryFilterTrigger extends StatelessWidget {
  const _MissingCountryFilterTrigger({
    required this.selected,
    required this.countries,
    required this.onSelect,
  });

  final String? selected;
  final List<String> countries;
  final void Function(String?) onSelect;

  String get _label => selected == null ? 'Todos' : selected!;

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MissingFilterSheet(
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
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder.withValues(alpha: 0.6)),
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
                Icon(Icons.filter_list_rounded, size: 22, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MissingFilterSheet extends StatelessWidget {
  const _MissingFilterSheet({
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
    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
                color: AppColors.placeholder.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Filtrar por país',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
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
                    _MissingFilterListTile(
                      label: 'Todos',
                      isSelected: selected == null,
                      onTap: () => onSelect(null),
                    ),
                    ...countries.map(
                      (code) => _MissingFilterListTile(
                        label: code,
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

class _MissingFilterListTile extends StatelessWidget {
  const _MissingFilterListTile({
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
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
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

class _MissingStickerCard extends StatelessWidget {
  const _MissingStickerCard({
    required this.stickerId,
    required this.onTap,
  });

  final String stickerId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stickerId,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                _stickerSubtitleFromId(stickerId),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddOneSheet extends StatelessWidget {
  const _AddOneSheet({
    required this.stickerId,
    required this.onAdded,
    required this.onMarkCollected,
  });

  final String stickerId;
  final VoidCallback onAdded;
  final Future<void> Function() onMarkCollected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
                color: AppColors.placeholder.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            stickerId,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            _stickerSubtitleFromId(stickerId),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () async {
                await onMarkCollected();
                if (context.mounted) onAdded();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Agregar 1'),
            ),
          ),
        ],
      ),
    );
  }
}
