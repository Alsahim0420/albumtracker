import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/album_section_item.dart';
import '../widgets/filter_segments.dart';
import '../widgets/flag_placeholder.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/home_header.dart';
import '../widgets/progress_card.dart';
import '../widgets/section_header.dart';
import '../widgets/sticker_item.dart';

/// Pantalla principal: progreso, filtros, secciones del álbum y navegación inferior.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeFilter _filter = HomeFilter.all;
  HomeNavItem _navIndex = HomeNavItem.album;

  static const int _collected = 637;
  static const int _total = 980;
  static const int _swapsAvailable = 34;

  late final List<AlbumSection> _sections = _buildMockSections();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(onProfileTap: () {}),
            ProgressCard(
              percent: 65,
              collected: _collected,
              total: _total,
              swapsAvailable: _swapsAvailable,
            ),
            FilterSegments(
              selected: _filter,
              onChanged: (v) => setState(() => _filter = v),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _sections.length,
                itemBuilder: (context, index) {
                  final section = _sections[index];
                  final items = _filteredItems(section.items);
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: section.title,
                        leading: section.flagCode != null
                            ? FlagPlaceholder(code: section.flagCode!)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            const crossCount = 5;
                            final size = (constraints.maxWidth - (crossCount - 1) * 8) / crossCount;
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: items
                                  .map(
                                    (item) => SizedBox(
                                      width: size,
                                      height: size,
                                      child: StickerItem(
                                        number: item.number,
                                        state: item.state,
                                        swapCount: item.swapCount,
                                        onTap: () {},
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _navIndex,
        onTap: (v) => setState(() => _navIndex = v),
        onFabTap: () {},
      ),
    );
  }

  List<AlbumStickerItem> _filteredItems(List<AlbumStickerItem> items) {
    switch (_filter) {
      case HomeFilter.all:
        return items;
      case HomeFilter.missing:
        return items.where((i) => i.state == StickerState.missing).toList();
      case HomeFilter.swaps:
        return items.where((i) => i.swapCount > 0).toList();
    }
  }

  static List<AlbumSection> _buildMockSections() {
    return [
      AlbumSection(
        title: 'FWC • INTRO',
        flagCode: null,
        items: const [
          AlbumStickerItem(number: 1, state: StickerState.collected),
          AlbumStickerItem(number: 2, state: StickerState.missing),
          AlbumStickerItem(number: 3, state: StickerState.hasSwaps, swapCount: 1),
          AlbumStickerItem(number: 4, state: StickerState.collected),
          AlbumStickerItem(number: 5, state: StickerState.collected),
        ],
      ),
      AlbumSection(
        title: 'FRA • FRANCE',
        flagCode: 'FRA',
        items: const [
          AlbumStickerItem(number: 6, state: StickerState.hasSwaps, swapCount: 3),
          AlbumStickerItem(number: 7, state: StickerState.collected),
          AlbumStickerItem(number: 8, state: StickerState.missing),
          AlbumStickerItem(number: 9, state: StickerState.collected),
          AlbumStickerItem(number: 10, state: StickerState.missing),
          AlbumStickerItem(number: 11, state: StickerState.missing),
          AlbumStickerItem(number: 12, state: StickerState.collected),
          AlbumStickerItem(number: 13, state: StickerState.collected),
          AlbumStickerItem(number: 14, state: StickerState.hasSwaps, swapCount: 1),
          AlbumStickerItem(number: 15, state: StickerState.missing),
          AlbumStickerItem(number: 16, state: StickerState.collected),
          AlbumStickerItem(number: 17, state: StickerState.collected),
          AlbumStickerItem(number: 18, state: StickerState.collected),
          AlbumStickerItem(number: 19, state: StickerState.missing),
          AlbumStickerItem(number: 20, state: StickerState.collected),
        ],
      ),
      AlbumSection(
        title: 'COL • COLOMBIA',
        flagCode: 'COL',
        items: List.generate(
          20,
          (i) => AlbumStickerItem(
            number: 21 + i,
            state: i < 4 ? StickerState.missing : StickerState.collected,
          ),
        ),
      ),
    ];
  }
}
