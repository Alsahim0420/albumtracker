// ignore_for_file: unnecessary_underscores

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:albumtracker/core/injection.dart';
import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/core/repository/album_repository.dart';
import 'package:albumtracker/core/storage/hive_storage.dart';
import 'package:albumtracker/features/home/data/services/sticker_image_input_service.dart';
import 'package:albumtracker/features/home/presentation/bloc/album_bloc.dart';
import 'package:albumtracker/features/home/presentation/bloc/album_event.dart';
import 'package:albumtracker/features/home/presentation/bloc/album_state.dart';
import 'package:albumtracker/features/settings/presentation/pages/settings_page.dart';
import 'package:albumtracker/features/home/presentation/models/group_team_item.dart';
import 'package:albumtracker/features/home/presentation/models/team_sticker_item.dart';
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
import 'package:albumtracker/features/home/presentation/widgets/sticker_count_sheet.dart';
import 'package:albumtracker/features/home/presentation/widgets/team_sticker_card.dart';
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
  bool _showScanProcessingOverlay = false;
  int _processingImageCount = 0;
  DateTime? _processingOverlayShownAt;
  static const Duration _minOverlayVisible = Duration(milliseconds: 650);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AlbumBloc, AlbumState>(
      listenWhen: (previous, current) =>
          (current is AlbumScanCompleted &&
              previous.scanResult != current.scanResult) ||
          current is AlbumError,
      listener: (context, state) {
        if (state is AlbumError) {
          _hideProcessingOverlayAfterMinimum();
          return;
        }
        if (state is! AlbumScanCompleted || state.scanResult == null) return;
        final result = state.scanResult!;
        _hideProcessingOverlayAfterMinimum().then((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!context.mounted) return;
            await showStickerScanResultDialog(context, result);
          });
        });
      },
      child: BlocBuilder<AlbumBloc, AlbumState>(
        builder: (context, state) {
          return Stack(
            children: [
              Scaffold(
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
              if (_showScanProcessingOverlay || state.isLoading)
                _StickerScanProcessingOverlay(
                  imageCount: _processingImageCount <= 0
                      ? 1
                      : _processingImageCount,
                ),
            ],
          );
        },
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
                  : _buildSpecialsBody(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpecialsBody() {
    final specials = _filterSpecialsByCategory(WorldCup2026Seed.specialStickers);
    int missing = 0;
    for (final s in specials) {
      final c = AlbumRepository.getStickerCount(s.id);
      if (c == 0) missing += 1;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'homeTabSpecials'.tr(args: [missing.toString()]),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const crossCount = 3;
              const spacing = 10.0;
              final size =
                  (constraints.maxWidth - (crossCount - 1) * spacing - 40) /
                      crossCount;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 104),
                child: Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: specials
                      .map(
                        (s) => SizedBox(
                          width: size,
                          height: size * 1.15,
                          child: TeamStickerCard(
                            sticker: _toSpecialStickerItem(s),
                            count: AlbumRepository.getStickerCount(s.id),
                            onTap: () => _openSpecialStickerSheet(s),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  TeamStickerItem _toSpecialStickerItem(StickerModel s) {
    return TeamStickerItem(
      code: s.code,
      displayCode: s.displayCode,
      globalNumber: s.globalNumber,
      label: s.displayLabel,
      name: null,
      type: TeamStickerType.special,
      collected: AlbumRepository.getStickerCount(s.id) > 0,
      duplicateCount:
          (AlbumRepository.getStickerCount(s.id) - 1).clamp(0, 999999),
    );
  }

  List<StickerModel> _filterSpecialsByCategory(List<StickerModel> specials) {
    return specials
        .where((s) => s.teamId == WorldCup2026Seed.specialTeamCode)
        .toList();
  }

  void _openSpecialStickerSheet(StickerModel sticker) {
    final count = AlbumRepository.getStickerCount(sticker.id);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StickerCountSheet(
        sticker: _toSpecialStickerItem(sticker),
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
              _showAddedList([
                _addedLineForSticker(sticker),
              ]);
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
    final proceed = await _showSpecialCaptureAdviceDialog();
    if (!mounted || !proceed) return;

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
    setState(() {
      _showScanProcessingOverlay = true;
      _processingImageCount = imagePaths.length;
      _processingOverlayShownAt = DateTime.now();
    });
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted) return;
    context.read<AlbumBloc>().add(AlbumScanImagesRequested(imagePaths));
  }

  Future<bool> _showSpecialCaptureAdviceDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text('scanSpecialTipTitle'.tr()),
          content: Text('scanSpecialTipBody'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('scanSpecialTipCancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              child: Text('scanSpecialTipContinue'.tr()),
            ),
          ],
        );
      },
    );
    return result ?? false;
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
          onConfirm: (stickerIds) async {
            context.read<AlbumBloc>().add(AlbumBulkAddRequested(stickerIds));
            final addedLines = <String>[];
            for (final id in stickerIds) {
              final sticker = WorldCup2026Seed.getStickerById(id);
              if (sticker != null) {
                addedLines.add(_addedLineForSticker(sticker));
              }
            }
            _showAddedList(addedLines.toSet().toList());
            if (context.mounted) setState(() {});
          },
        ),
      ),
    );
  }

  Future<void> _hideProcessingOverlayAfterMinimum() async {
    final shownAt = _processingOverlayShownAt;
    if (shownAt != null) {
      final elapsed = DateTime.now().difference(shownAt);
      final wait = _minOverlayVisible - elapsed;
      if (wait > Duration.zero) {
        await Future<void>.delayed(wait);
      }
    }
    if (!mounted) return;
    setState(() {
      _showScanProcessingOverlay = false;
      _processingImageCount = 0;
      _processingOverlayShownAt = null;
    });
  }
}

class _StickerScanProcessingOverlay extends StatelessWidget {
  const _StickerScanProcessingOverlay({required this.imageCount});

  final int imageCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _BouncingBallLoader(),
                    const SizedBox(height: 12),
                    Text(
                      imageCount == 1
                          ? 'Analizando imagen...'
                          : 'Analizando imagenes...',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Esto puede tardar unos segundos',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BouncingBallLoader extends StatefulWidget {
  const _BouncingBallLoader();

  @override
  State<_BouncingBallLoader> createState() => _BouncingBallLoaderState();
}

class _BouncingBallLoaderState extends State<_BouncingBallLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..repeat(reverse: true);

  late final Animation<double> _jump = Tween<double>(
    begin: 0,
    end: -14,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

  late final Animation<double> _shadow = Tween<double>(
    begin: 1,
    end: 0.65,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 72,
      height: 58,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 6,
                child: Transform.scale(
                  scaleX: _shadow.value,
                  child: Container(
                    width: 32,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.onSurface.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, _jump.value),
                child: Icon(
                  Icons.sports_soccer_rounded,
                  size: 36,
                  color: colors.primary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
