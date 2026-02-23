import 'package:flutter/material.dart';

import 'package:albumtracker/core/constants/app_constants.dart';
import 'package:albumtracker/core/theme/app_colors.dart';
import 'package:albumtracker/features/home/presentation/models/group_team_item.dart';
import 'package:albumtracker/features/home/presentation/models/team_sticker_item.dart';
import 'package:albumtracker/features/home/presentation/widgets/flag_placeholder.dart';
import '../widgets/sticker_count_sheet.dart';
import 'package:albumtracker/features/home/presentation/widgets/team_completion_card.dart';
import 'package:albumtracker/features/home/presentation/widgets/team_sticker_card.dart';
import 'package:albumtracker/features/home/presentation/widgets/team_sticker_filter_tabs.dart';

/// Vista de detalle de un equipo: cabecera, estado, filtros y rejilla de pegatinas.
class TeamDetailPage extends StatefulWidget {
  const TeamDetailPage({
    super.key,
    required this.team,
    required this.groupName,
  });

  final TeamProgress team;
  final String groupName;

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> {
  TeamStickerFilter _filter = TeamStickerFilter.all;
  late final List<TeamStickerItem> _stickers = _buildMockStickers();
  late final Map<String, int> _stickerCounts = _initCounts();

  Map<String, int> _initCounts() {
    final map = <String, int>{};
    for (final s in _stickers) {
      map[s.code] = s.collected ? (1 + s.duplicateCount) : 0;
    }
    return map;
  }

  int _countFor(TeamStickerItem s) => _stickerCounts[s.code] ?? 0;

  void _openStickerSheet(TeamStickerItem sticker) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StickerCountSheet(
        sticker: sticker,
        initialCount: _countFor(sticker),
        onDone: (count) {
          setState(() => _stickerCounts[sticker.code] = count);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _stickers.length;
    final found = _stickers.where((s) => _countFor(s) > 0).length;
    final missing = total - found;
    final duplicateCount = _stickers.where((s) => _countFor(s) > 1).length;
    final filtered = _filteredStickers();

    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      appBar: AppBar(
        backgroundColor: AppColors.splashBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppConstants.teamDetailBackGroups,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 22),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary, size: 22),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TeamHeader(
              teamName: widget.team.name,
              groupName: widget.groupName,
              flagCode: widget.team.flagCode,
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
                AppConstants.teamDetailSquadMembers,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.placeholder,
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
                  const crossCount = 3;
                  final spacing = 10.0;
                  final size = (constraints.maxWidth - (crossCount - 1) * spacing) / crossCount;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: filtered
                        .map(
                          (s) => SizedBox(
                            width: size,
                            height: size * 1.15,
                            child: TeamStickerCard(
                              sticker: s,
                              count: _countFor(s),
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
  }

  List<TeamStickerItem> _filteredStickers() {
    switch (_filter) {
      case TeamStickerFilter.all:
        return _stickers;
      case TeamStickerFilter.missing:
        return _stickers.where((s) => _countFor(s) == 0).toList();
      case TeamStickerFilter.duplicates:
        return _stickers.where((s) => _countFor(s) > 1).toList();
    }
  }

  List<TeamStickerItem> _buildMockStickers() {
    final prefix = widget.team.flagCode ?? 'T';
    return [
      TeamStickerItem(
        code: '$prefix 00',
        label: AppConstants.teamDetailTeamBadge,
        type: TeamStickerType.badge,
        collected: true,
      ),
      TeamStickerItem(
        code: '$prefix 01',
        label: AppConstants.teamDetailTeamPhoto,
        type: TeamStickerType.photo,
        collected: false,
      ),
      TeamStickerItem(code: '$prefix 1', label: 'G. OCHOA', type: TeamStickerType.player, collected: true, duplicateCount: 1),
      TeamStickerItem(code: '$prefix 2', label: 'J. SÁNCHEZ', type: TeamStickerType.player, collected: true, duplicateCount: 1),
      TeamStickerItem(code: '$prefix 3', label: 'MONTES', type: TeamStickerType.player, collected: false),
      TeamStickerItem(code: '$prefix 4', label: 'E. ÁLVAREZ', type: TeamStickerType.player, collected: true),
      TeamStickerItem(code: '$prefix 5', label: 'J. VÁSQUEZ', type: TeamStickerType.player, collected: true),
      TeamStickerItem(code: '$prefix 6', label: 'ARTEAGA', type: TeamStickerType.player, collected: false),
      TeamStickerItem(code: '$prefix 7', label: 'L. ROMO', type: TeamStickerType.player, collected: true),
      TeamStickerItem(code: '$prefix 8', label: 'C. RODRIGUEZ', type: TeamStickerType.player, collected: true),
      TeamStickerItem(code: '$prefix 9', label: 'R. JIMÉNEZ', type: TeamStickerType.player, collected: true),
      TeamStickerItem(code: '$prefix 10', label: '10', type: TeamStickerType.player, collected: false),
      TeamStickerItem(code: '$prefix 11', label: 'S. GIMÉNEZ', type: TeamStickerType.player, collected: true),
      TeamStickerItem(code: '$prefix 12', label: '12', type: TeamStickerType.player, collected: false),
      TeamStickerItem(code: '$prefix 13', label: '13', type: TeamStickerType.player, collected: true),
      TeamStickerItem(code: '$prefix 14', label: '14', type: TeamStickerType.player, collected: true),
      TeamStickerItem(code: '$prefix 15', label: '15', type: TeamStickerType.player, collected: true),
      TeamStickerItem(code: '$prefix 16', label: '16', type: TeamStickerType.player, collected: true),
      TeamStickerItem(code: '$prefix 17', label: '17', type: TeamStickerType.player, collected: true),
      TeamStickerItem(code: '$prefix 18', label: '18', type: TeamStickerType.player, collected: false),
      TeamStickerItem(code: '$prefix 19', label: '19', type: TeamStickerType.player, collected: false),
      TeamStickerItem(code: '$prefix 20', label: '20', type: TeamStickerType.player, collected: false),
    ];
  }
}

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({
    required this.teamName,
    required this.groupName,
    this.flagCode,
  });

  final String teamName;
  final String groupName;
  final String? flagCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 36,
            child: flagCode != null
                ? FittedBox(
                    fit: BoxFit.contain,
                    child: FlagPlaceholder(code: flagCode!),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.inputBorder,
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
                  AppConstants.teamDetailGroupEvent.replaceFirst('%s', groupName),
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
