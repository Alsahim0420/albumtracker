// ignore_for_file: unnecessary_underscores

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:albumtracker/core/injection.dart';
import 'package:albumtracker/core/repository/album_repository.dart';
import 'package:albumtracker/core/storage/hive_storage.dart';
import 'package:albumtracker/features/home/data/services/sticker_image_input_service.dart';
import 'package:albumtracker/features/home/presentation/bloc/album_bloc.dart';
import 'package:albumtracker/features/home/presentation/bloc/album_event.dart';
import 'package:albumtracker/features/home/presentation/bloc/album_state.dart';
import 'package:albumtracker/features/settings/presentation/pages/settings_page.dart';
import 'package:albumtracker/features/home/presentation/models/group_team_item.dart';
import 'package:albumtracker/features/home/presentation/widgets/bulk_add_stickers_sheet.dart';
import 'package:albumtracker/features/home/presentation/widgets/group_section.dart';
import 'package:albumtracker/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:albumtracker/features/home/presentation/widgets/home_header_v2.dart';
import 'package:albumtracker/features/home/presentation/widgets/home_tabs.dart';
import 'package:albumtracker/features/home/presentation/widgets/missing_stickers_view.dart';
import 'package:albumtracker/features/home/presentation/widgets/repeated_stickers_view.dart';
import 'package:albumtracker/features/home/presentation/widgets/capture_review_sheet.dart';
import 'package:albumtracker/features/home/presentation/widgets/sticker_scan_options_sheet.dart';
import 'package:albumtracker/features/home/presentation/widgets/sticker_scan_result_dialog.dart';
import 'package:albumtracker/features/home/presentation/widgets/total_collection_card.dart';
import 'package:albumtracker/features/home/presentation/pages/team_detail_page.dart';

/// Pantalla principal: World Cup 2026, tabs, total collection y grupos con equipos.
class HomePage extends StatefulWidget {
  final Function(String?) onThemeChanged;
  final void Function(ThemeMode mode)? onThemeModeChanged;

  const HomePage({
    super.key,
    required this.onThemeChanged,
    this.onThemeModeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeTab _tab = HomeTab.homeTabGroups;
  HomeNavItem _navIndex = HomeNavItem.album;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AlbumBloc, AlbumState>(
      listenWhen: (previous, current) =>
          current is AlbumScanCompleted &&
          previous.scanResult != current.scanResult,
      listener: (context, state) {
        if (state is! AlbumScanCompleted || state.scanResult == null) return;
        final result = state.scanResult!;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;
          await showStickerScanResultDialog(context, result);
        });
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(child: _buildBody()),
        floatingActionButton: _navIndex == HomeNavItem.album
            ? FloatingActionButton(
                onPressed: _openFabActionSheet,
                elevation: 6,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: const Icon(Icons.add, size: 28),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: HomeBottomNav(
          currentIndex: _navIndex,
          onTap: (v) => setState(() => _navIndex = v),
        ),
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
        return SettingsPage(
          onThemeChanged: widget.onThemeChanged,
          onThemeModeChanged: widget.onThemeModeChanged,
        );
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
              child: _tab == HomeTab.homeTabGroups
                  ? ListView(
                      padding: const EdgeInsets.only(bottom: 104),
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
      case HomeTab.homeTabGroups:
        return 'homeTabGroups'.tr();
      case HomeTab.homeTabTeams:
        return 'homeTabTeams'.tr();
      case HomeTab.homeTabSpecials:
        return 'homeTabSpecials'.tr();
      case HomeTab.homeTabMarketplace:
        return 'homeTabMarketplace'.tr();
    }
  }

  void _openTeamDetail(TeamProgress team, String groupName) {
    final teamId = AlbumRepository.getTeamIdByGroupAndTeamName(
      groupName,
      team.name,
    );
    if (teamId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeamDetailPage(teamId: teamId, groupName: groupName),
      ),
    );
  }

  void _openFabActionSheet() {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      builder: (context) => StickerScanOptionsSheet(
        onActionSelected: (action) {
          Navigator.of(context).pop();
          _handleFabAction(action);
        },
      ),
    );
  }

  Future<void> _handleFabAction(StickerScanInputAction action) async {
    if (action == StickerScanInputAction.manualBulk) {
      _openBulkAddSheet();
      return;
    }

    final inputService = sl<StickerImageInputService>();
    List<String> imagePaths = const [];
    switch (action) {
      case StickerScanInputAction.captureSingle:
        imagePaths = await inputService.captureSinglePhoto();
        break;
      case StickerScanInputAction.captureMultiple:
        imagePaths = await _runCameraCaptureSession(inputService);
        break;
      case StickerScanInputAction.gallerySingle:
        imagePaths = await inputService.pickSingleFromGallery();
        break;
      case StickerScanInputAction.galleryMultiple:
        imagePaths = await inputService.pickMultipleFromGallery();
        break;
      case StickerScanInputAction.manualBulk:
        break;
    }

    if (!mounted || imagePaths.isEmpty) return;
    context.read<AlbumBloc>().add(AlbumScanImagesRequested(imagePaths));
  }

  /// Sesión multi-foto: una captura → revisión → repetir / añadir otra / finalizar.
  /// OCR solo al terminar la sesión con las rutas confirmadas.
  Future<List<String>> _runCameraCaptureSession(
    StickerImageInputService inputService,
  ) async {
    final confirmed = <String>[];
    while (mounted) {
      final shot = await inputService.captureSinglePhoto();
      if (shot.isEmpty) {
        if (confirmed.isEmpty) return [];
        return confirmed;
      }
      final path = shot.first;
      if (!mounted) return confirmed;

      final decision = await showModalBottomSheet<CaptureReviewDecision>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (ctx) => CaptureReviewSheet(
          imagePath: path,
          photoNumber: confirmed.length + 1,
        ),
      );

      if (!mounted) return confirmed;

      switch (decision) {
        case CaptureReviewDecision.retake:
          continue;
        case CaptureReviewDecision.saveAndContinue:
          confirmed.add(path);
          continue;
        case CaptureReviewDecision.saveAndFinish:
          confirmed.add(path);
          return confirmed;
        case null:
          return confirmed;
      }
    }
    return confirmed;
  }

  void _openBulkAddSheet() {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
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
