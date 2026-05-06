// ignore_for_file: unused_local_variable, unnecessary_underscores

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/core/models/team_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:albumtracker/core/i18n/group_localization.dart';
import 'package:albumtracker/core/repository/album_repository.dart';
import 'package:albumtracker/core/storage/hive_storage.dart';
import 'package:albumtracker/features/home/presentation/bloc/album_bloc.dart';
import 'package:albumtracker/features/home/presentation/bloc/album_event.dart';
import 'package:albumtracker/features/home/presentation/bloc/album_state.dart';
import 'package:albumtracker/features/home/presentation/models/team_sticker_item.dart';
import 'package:albumtracker/features/home/presentation/widgets/flag_placeholder.dart';
import 'package:albumtracker/features/home/presentation/widgets/share_sticker_list_images.dart';
import '../widgets/sticker_count_sheet.dart';
import 'package:albumtracker/features/home/presentation/widgets/team_completion_card.dart';
import 'package:albumtracker/features/home/presentation/widgets/team_sticker_card.dart';
import 'package:albumtracker/features/home/presentation/widgets/team_sticker_filter_tabs.dart';

/// Vista de detalle de un equipo: cabecera, estado, filtros y rejilla de laminas.
class TeamDetailPage extends StatelessWidget {
  const TeamDetailPage({
    super.key,
    required this.teamId,
    required this.groupName,
  });

  final String teamId;
  final String groupName;

  @override
  Widget build(BuildContext context) {
    final team = AlbumRepository.getTeamById(teamId);
    if (team == null) {
      return Scaffold(
        appBar: AppBar(title: Text('team'.tr())),
        body: Center(child: Text('teamNotFound'.tr())),
      );
    }
    return _TeamDetailBody(team: team, groupName: groupName);
  }
}

class _TeamDetailBody extends StatefulWidget {
  const _TeamDetailBody({required this.team, required this.groupName});

  final TeamModel team;
  final String groupName;

  @override
  State<_TeamDetailBody> createState() => _TeamDetailBodyState();
}

class _TeamDetailBodyState extends State<_TeamDetailBody> {
  TeamStickerFilter _filter = TeamStickerFilter.all;
  bool _isSharingTeam = false;

  int _countFor(StickerModel s) => AlbumRepository.getStickerCount(s.id);

  List<TeamStickerItem> _toStickerItems() {
    final stickers = widget.team.stickers;
    return stickers.map((s) {
      final count = _countFor(s);
      return TeamStickerItem(
        code: s.code,
        displayCode: s.displayCode,
        globalNumber: s.globalNumber,
        label: s.displayLabel,
        name: s.playerName,
        type: _stickerType(s.type),
        collected: count > 0,
        duplicateCount: count > 1 ? count - 1 : 0,
      );
    }).toList();
  }

  TeamStickerType _stickerType(StickerType t) {
    switch (t) {
      case StickerType.badge:
        return TeamStickerType.badge;
      case StickerType.team_photo:
        return TeamStickerType.photo;
      case StickerType.player:
        return TeamStickerType.player;
      case StickerType.special:
        return TeamStickerType.special;
    }
  }

  void _openStickerSheet(StickerModel sticker) {
    final count = _countFor(sticker);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StickerCountSheet(
        sticker: _toStickerItems().firstWhere((i) => i.code == sticker.code),
        initialCount: count,
        onDone: (newCount) async {
          if (ctx.mounted) {
            ctx.read<AlbumBloc>().add(
              AlbumUpdateStickerCountRequested(
                stickerId: sticker.id,
                count: newCount,
              ),
            );
            if (newCount > count) {
              _showAddedList([_addedLineForSticker(sticker)]);
            }
          }
        },
      ),
    );
  }

  String _addedLineForSticker(StickerModel sticker) {
    final team = sticker.teamId.tr();
    switch (sticker.type) {
      case StickerType.badge:
        return 'Insignia - $team';
      case StickerType.team_photo:
        return 'Foto de equipo - $team';
      case StickerType.player:
        final name = (sticker.playerName ?? '').trim();
        if (name.isNotEmpty) return '$name - $team';
        return 'Jugador - $team';
      case StickerType.special:
        return 'Especial - ${sticker.displayCode}';
    }
  }

  void _showAddedList(List<String> lines) {
    if (!mounted || lines.isEmpty) return;
    final text = lines.join('\n');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Agregadas:\n$text'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final team = widget.team;
    final stickers = team.stickers;
    final total = stickers.length;
    int found = 0;
    int duplicateCount = 0;
    for (final s in stickers) {
      final c = _countFor(s);
      if (c > 0) found++;
      if (c > 1) duplicateCount += c - 1;
    }
    final missing = total - found;
    final filtered = _filteredStickers(stickers);
    return BlocListener<AlbumBloc, AlbumState>(
      listener: (context, state) {
        if (state is AlbumLoaded) {
          setState(() {});
        }
      },
      child: ValueListenableBuilder<Box>(
        valueListenable: collectionBox.listenable(),
        builder: (context, __, ___) {
          return Scaffold(
            backgroundColor: colors.surface,
            appBar: AppBar(
              backgroundColor: colors.surface,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: colors.onSurface,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'teamDetailBackGroups'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  onPressed: _isSharingTeam
                      ? null
                      : () =>
                            _shareTeamStickers(context, stickers, found, total),
                  icon: _isSharingTeam
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onSurface,
                          ),
                        )
                      : Icon(
                          Icons.share_outlined,
                          color: colors.onSurface,
                          size: 22,
                        ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TeamHeader(
                    teamName: team.name.tr(),
                    groupName: widget.groupName,
                    flagAssetPath: team.flagAssetPath ?? '',
                  ),
                  const SizedBox(height: 16),
                  TeamCompletionCard(
                    total: total,
                    found: found,
                    missing: missing,
                  ),
                  TeamStickerFilterTabs(
                    selected: _filter,
                    duplicateCount: duplicateCount,
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'teamDetailSquadMembers'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final colors = Theme.of(context).colorScheme;
                        const crossCount = 3;
                        final spacing = 10.0;
                        final size =
                            (constraints.maxWidth -
                                (crossCount - 1) * spacing) /
                            crossCount;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: filtered
                              .map(
                                (s) => SizedBox(
                                  width: size,
                                  height: size * 1.15,
                                  child: TeamStickerCard(
                                    sticker: _toStickerItems().firstWhere(
                                      (i) => i.code == s.code,
                                    ),
                                    count: _countFor(s),
                                    teamFlagAssetPath:
                                        widget.team.flagAssetPath,
                                    onTap: () => _openStickerSheet(s),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<StickerModel> _filteredStickers(List<StickerModel> stickers) {
    switch (_filter) {
      case TeamStickerFilter.all:
        return stickers;
      case TeamStickerFilter.missing:
        return stickers.where((s) => _countFor(s) == 0).toList();
      case TeamStickerFilter.duplicates:
        return stickers.where((s) => _countFor(s) > 1).toList();
    }
  }

  Future<void> _shareTeamStickers(
    BuildContext context,
    List<StickerModel> stickers,
    int found,
    int total,
  ) async {
    if (_isSharingTeam) return;
    setState(() => _isSharingTeam = true);

    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(box.size.center(Offset.zero)) & const Size(1, 1);
      final isEs = context.locale.languageCode.toLowerCase().startsWith('es');
      final teamName = widget.team.name.tr();
      final items = stickers.map((sticker) {
        final count = _countFor(sticker);
        final hasSticker = count > 0;
        final repeated = count > 1 ? count - 1 : 0;
        final status = hasSticker
            ? (repeated > 0
                  ? (isEs ? 'Tiene ($repeated)' : 'Owned ($repeated)')
                  : (isEs ? 'Tiene' : 'Owned'))
            : (isEs ? 'Falta' : 'Missing');
        return ShareStickerListItem.fromStickerId(
          sticker.id,
          tone: hasSticker
              ? (repeated > 0
                    ? ShareStickerTileTone.duplicate
                    : ShareStickerTileTone.owned)
              : ShareStickerTileTone.missing,
          trailingText: status,
          textSuffix: status,
        );
      }).toList();

      await ShareStickerListImages.share(
        context: context,
        items: items,
        total: found,
        config: ShareStickerListConfig(
          title: teamName,
          totalLabel: isEs ? 'de $total' : 'of $total',
          stickerColumnLabel: isEs ? 'Lamina' : 'Sticker',
          trailingColumnLabel: isEs ? 'Estado' : 'Status',
          footer: isEs
              ? 'Resumen de pais generado desde Album Collect 2026'
              : 'Country summary generated from Album Collect 2026',
          message: isEs
              ? '$teamName: tengo $found de $total laminas en Album Collect 2026.'
              : '$teamName: I have $found of $total stickers in Album Collect 2026.',
          fileBaseName: 'album_collect_${widget.team.id.toLowerCase()}',
          gridColumns: 4,
          moreLabel: (count) => isEs
              ? '+ $count laminas mas de $teamName'
              : '+ $count more stickers from $teamName',
        ),
        subject: '$teamName - Album Collect 2026',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      debugPrint('[TEAM_SHARE_DEBUG] failed error=$e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo compartir')));
      }
    } finally {
      if (mounted) setState(() => _isSharingTeam = false);
    }
  }
}

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({
    required this.teamName,
    required this.groupName,
    required this.flagAssetPath,
  });

  final String teamName;
  final String groupName;
  final String flagAssetPath;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 36,
            child: flagAssetPath.isNotEmpty
                ? FittedBox(
                    fit: BoxFit.contain,
                    child: FlagPlaceholder(code: flagAssetPath),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'teamDetailGroupEvent'.tr(
                    args: [localizedGroupDisplayName(groupName)],
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
