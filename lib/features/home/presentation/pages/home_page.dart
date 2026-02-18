import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../models/group_team_item.dart';
import '../widgets/bulk_add_stickers_sheet.dart';
import '../widgets/group_section.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/home_header_v2.dart';
import '../widgets/home_tabs.dart';
import 'team_detail_page.dart';
import '../widgets/total_collection_card.dart';

/// Pantalla principal: World Cup 2026, tabs, total collection y grupos con equipos.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeTab _tab = HomeTab.groups;
  HomeNavItem _navIndex = HomeNavItem.album;

  static const int _totalCollected = 342;
  static const int _totalStickers = 870;
  static const int _moreGroupsCount = 14;

  late final List<GroupWithTeams> _groups = _buildMockGroups();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: _navIndex == HomeNavItem.settings
            ? const SettingsPage()
            : _buildAlbumBody(),
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _navIndex,
        onTap: (v) => setState(() => _navIndex = v),
        onFabTap: _openBulkAddSheet,
        showFab: _navIndex == HomeNavItem.album,
      ),
    );
  }

  Widget _buildAlbumBody() {
    return Column(
      children: [
        HomeHeaderV2(onSearch: () {}),
        TotalCollectionCard(
          collected: _totalCollected,
          total: _totalStickers,
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
                    ..._groups.map(
                      (g) => GroupSection(
                        group: g,
                        onTeamTap: (team) => _openTeamDetail(team, g.name),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ShowMoreGroupsButton(
                      count: _moreGroupsCount,
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),
                  ],
                )
              : _buildPlaceholderTab(),
        ),
      ],
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeamDetailPage(team: team, groupName: groupName),
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
          onConfirm: (numbers) {
            // TODO: integrar con lógica de álbum
          },
        ),
      ),
    );
  }

  static List<GroupWithTeams> _buildMockGroups() {
    return [
      GroupWithTeams(
        name: 'Group A',
        teams: const [
          TeamProgress(name: 'USA', flagCode: 'USA', collected: 14, total: 20),
          TeamProgress(name: 'Mexico', flagCode: 'MEX', collected: 20, total: 20),
          TeamProgress(name: 'Canada', flagCode: 'CAN', collected: 12, total: 20),
          TeamProgress(name: 'Costa Rica', flagCode: 'CRI', collected: 8, total: 20),
        ],
      ),
      GroupWithTeams(
        name: 'Group B',
        teams: const [
          TeamProgress(name: 'Argentina', flagCode: 'ARG', collected: 12, total: 20),
          TeamProgress(name: 'Brazil', flagCode: 'BRA', collected: 9, total: 20),
        ],
      ),
    ];
  }
}

class _ShowMoreGroupsButton extends StatelessWidget {
  const _ShowMoreGroupsButton({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.inputBorder),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            AppConstants.homeShowMoreGroups.replaceFirst('%s', '$count'),
          ),
        ),
      ),
    );
  }
}
