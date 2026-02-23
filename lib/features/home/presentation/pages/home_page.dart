// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:albumtracker/core/constants/app_constants.dart';
import 'package:albumtracker/core/repository/album_repository.dart';
import 'package:albumtracker/core/storage/hive_storage.dart';
import 'package:albumtracker/features/home/presentation/bloc/album_bloc.dart';
import 'package:albumtracker/features/home/presentation/bloc/album_event.dart';
import 'package:albumtracker/core/theme/app_colors.dart';
import 'package:albumtracker/features/settings/presentation/pages/settings_page.dart';
import 'package:albumtracker/features/home/presentation/models/group_team_item.dart';
import 'package:albumtracker/features/home/presentation/widgets/bulk_add_stickers_sheet.dart';
import 'package:albumtracker/features/home/presentation/widgets/group_section.dart';
import 'package:albumtracker/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:albumtracker/features/home/presentation/widgets/home_header_v2.dart';
import 'package:albumtracker/features/home/presentation/widgets/home_tabs.dart';
import 'package:albumtracker/features/home/presentation/widgets/missing_stickers_view.dart';
import 'package:albumtracker/features/home/presentation/widgets/repeated_stickers_view.dart';
import 'package:albumtracker/features/home/presentation/widgets/total_collection_card.dart';
import 'package:albumtracker/features/home/presentation/pages/team_detail_page.dart';

/// Pantalla principal: World Cup 2026, tabs, total collection y grupos con equipos.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeTab _tab = HomeTab.groups;
  HomeNavItem _navIndex = HomeNavItem.album;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _navIndex,
        onTap: (v) => setState(() => _navIndex = v),
        onFabTap: _openBulkAddSheet,
        showFab: _navIndex == HomeNavItem.album,
      ),
    );
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case HomeNavItem.album:
        return _buildAlbumBody();
      case HomeNavItem.repeated:
        return const RepeatedStickersView();
      case HomeNavItem.missing:
        return const MissingStickersView();
      case HomeNavItem.settings:
        return const SettingsPage();
    }
  }

  Widget _buildAlbumBody() {
    return ValueListenableBuilder(
      valueListenable: collectionBox.listenable(),
      builder: (context, __, ___) {
        final stats = AlbumRepository.getGlobalStats();
        final groups = AlbumRepository.getGroupsWithProgress();
        return Column(
          children: [
            HomeHeaderV2(onSearch: () {}),
            TotalCollectionCard(
              collected: stats.collectedStickers,
              total: stats.totalStickers,
            ),
            HomeTabs(
              selected: _tab,
              onChanged: (v) => setState(() => _tab = v),
            ),
            Expanded(
              child: _tab == HomeTab.groups
                  ? ListView(
                      padding: const EdgeInsets.only(bottom: 88),
                      children: [
                        ...groups.map(
                          (g) => GroupSection(
                            group: g,
                            onTeamTap: (team) => _openTeamDetail(team, g.name),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    )
                  : _buildPlaceholderTab(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholderTab() {
    return Center(
      child: Text(
        _tabLabel(_tab),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  String _tabLabel(HomeTab tab) {
    switch (tab) {
      case HomeTab.groups:
        return AppConstants.homeTabGroups;
      case HomeTab.teams:
        return AppConstants.homeTabTeams;
      case HomeTab.specials:
        return AppConstants.homeTabSpecials;
      case HomeTab.marketplace:
        return AppConstants.homeTabMarketplace;
    }
  }

  void _openTeamDetail(TeamProgress team, String groupName) {
    final teamId = AlbumRepository.getTeamIdByGroupAndTeamName(groupName, team.name);
    if (teamId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeamDetailPage(teamId: teamId, groupName: groupName),
      ),
    );
  }

  void _openBulkAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BulkAddStickersSheet(
          onConfirm: (globalNumbers) async {
            context.read<AlbumBloc>().add(AlbumBulkAddRequested(globalNumbers));
            if (context.mounted) setState(() {});
          },
        ),
      ),
    );
  }
}
