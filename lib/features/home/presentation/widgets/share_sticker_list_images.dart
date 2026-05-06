import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/models/sticker_model.dart';

class ShareStickerListItem {
  const ShareStickerListItem({
    required this.code,
    required this.title,
    required this.teamName,
    required this.teamCode,
    this.tone = ShareStickerTileTone.neutral,
    this.trailingText,
    this.textSuffix,
  });

  final String code;
  final String title;
  final String teamName;
  final String teamCode;
  final ShareStickerTileTone tone;
  final String? trailingText;
  final String? textSuffix;

  static ShareStickerListItem fromStickerId(
    String stickerId, {
    String? trailingText,
    String? textSuffix,
    ShareStickerTileTone tone = ShareStickerTileTone.neutral,
  }) {
    final sticker = WorldCup2026Seed.getStickerById(stickerId);
    final teamCode = sticker?.teamId ?? _teamCodeFromStickerId(stickerId);
    final team = WorldCup2026Seed.getTeamById(teamCode);
    return ShareStickerListItem(
      code:
          sticker?.displayCode ??
          WorldCup2026Seed.stickerNumberLabel(stickerId),
      title: _shareTitleForSticker(stickerId),
      teamName: team?.name.tr() ?? teamCode,
      teamCode: teamCode,
      tone: tone,
      trailingText: trailingText,
      textSuffix: textSuffix,
    );
  }
}

enum ShareStickerTileTone { neutral, owned, missing, duplicate }

class ShareStickerListConfig {
  const ShareStickerListConfig({
    required this.title,
    required this.totalLabel,
    required this.stickerColumnLabel,
    required this.trailingColumnLabel,
    required this.footer,
    required this.message,
    required this.fileBaseName,
    this.gridColumns = 5,
    this.moreLabel,
  });

  final String title;
  final String totalLabel;
  final String stickerColumnLabel;
  final String trailingColumnLabel;
  final String footer;
  final String message;
  final String fileBaseName;
  final int gridColumns;
  final String Function(int count)? moreLabel;
}

class ShareStickerListImages {
  static const int maxPages = 30;
  static const int gridRowsPerPage = 10;

  static Future<void> share({
    required BuildContext context,
    required List<ShareStickerListItem> items,
    required int total,
    required ShareStickerListConfig config,
    required String subject,
    Rect? sharePositionOrigin,
  }) async {
    final sorted = _sortedItems(items);
    final locale = context.locale.languageCode;
    final palette = _ShareImagePalette.fromColorScheme(
      Theme.of(context).colorScheme,
    );
    final images = await _renderPngPages(
      items: sorted,
      total: total,
      config: config,
      locale: locale,
      palette: palette,
    );
    final text = renderTextList(items: sorted, config: config);
    if (!context.mounted) return;
    await Share.shareXFiles(
      [
        for (var i = 0; i < images.length; i++)
          XFile.fromData(
            images[i],
            mimeType: 'image/png',
            name: '${config.fileBaseName}_${i + 1}.png',
          ),
      ],
      subject: subject,
      text: text,
      fileNameOverrides: [
        for (var i = 0; i < images.length; i++)
          '${config.fileBaseName}_${i + 1}.png',
      ],
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<List<Uint8List>> _renderPngPages({
    required List<ShareStickerListItem> items,
    required int total,
    required ShareStickerListConfig config,
    required String locale,
    required _ShareImagePalette palette,
  }) async {
    final pageCount = math.max(
      1,
      math.min(maxPages, (items.length / _itemsPerPage(config)).ceil()),
    );
    final images = <Uint8List>[];
    for (var pageIndex = 0; pageIndex < pageCount; pageIndex++) {
      final start = pageIndex * _itemsPerPage(config);
      final end = math.min(start + _itemsPerPage(config), items.length);
      final hiddenCount = pageIndex == pageCount - 1
          ? math.max(0, items.length - end)
          : 0;
      images.add(
        await _renderPngPage(
          items: items.sublist(start, end),
          hiddenCount: hiddenCount,
          total: total,
          config: config,
          locale: locale,
          palette: palette,
          pageNumber: pageIndex + 1,
          pageCount: pageCount,
        ),
      );
    }
    return images;
  }

  static String renderTextList({
    required List<ShareStickerListItem> items,
    required ShareStickerListConfig config,
  }) {
    final buffer = StringBuffer()
      ..writeln(config.message)
      ..writeln()
      ..writeln(config.title);
    for (final item in items) {
      final suffix = item.textSuffix;
      buffer.writeln(
        suffix == null || suffix.isEmpty ? item.code : '${item.code} $suffix',
      );
    }
    return buffer.toString().trimRight();
  }

  static Future<Uint8List> _renderPngPage({
    required List<ShareStickerListItem> items,
    required int hiddenCount,
    required int total,
    required ShareStickerListConfig config,
    required String locale,
    required _ShareImagePalette palette,
    required int pageNumber,
    required int pageCount,
  }) async {
    const width = 1080.0;
    final columns = _normalizedColumns(config);
    final rows = math.max(1, (items.length / columns).ceil());
    final height = math.max(
      720.0,
      312.0 +
          rows * 92.0 +
          math.max(0, rows - 1) * 18.0 +
          (hiddenCount > 0 ? 96.0 : 44.0),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(width, height);
    _paintBackground(canvas, size, palette);
    _paintCard(
      canvas,
      size,
      items,
      hiddenCount,
      total,
      config,
      locale,
      palette,
      pageNumber,
      pageCount,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw StateError('Could not render shared sticker list image');
    }
    return byteData.buffer.asUint8List();
  }

  static void _paintBackground(
    Canvas canvas,
    Size size,
    _ShareImagePalette palette,
  ) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [palette.backgroundStart, palette.backgroundMid, palette.backgroundEnd],
        const [0, 0.58, 1],
      );
    canvas.drawRect(Offset.zero & size, paint);

    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.1),
      180,
      Paint()..color = palette.orb.withValues(alpha: 0.14),
    );
    canvas.drawCircle(
      Offset(size.width * 0.04, size.height * 0.88),
      240,
      Paint()..color = palette.orb.withValues(alpha: 0.18),
    );
  }

  static void _paintCard(
    Canvas canvas,
    Size size,
    List<ShareStickerListItem> items,
    int hiddenCount,
    int total,
    ShareStickerListConfig config,
    String locale,
    _ShareImagePalette palette,
    int pageNumber,
    int pageCount,
  ) {
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(72, 72, 936, size.height - 144),
      const Radius.circular(34),
    );
    canvas.drawRRect(card, Paint()..color = palette.card);

    final topBand = RRect.fromRectAndCorners(
      const Rect.fromLTWH(72, 72, 936, 164),
      topLeft: const Radius.circular(34),
      topRight: const Radius.circular(34),
    );
    canvas.drawRRect(topBand, Paint()..color = palette.topBand);

    _drawText(
      canvas,
      pageCount > 1 ? '${config.title} $pageNumber/$pageCount' : config.title,
      const Offset(120, 116),
      maxWidth: 540,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 44,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );

    final totalPill = RRect.fromRectAndRadius(
      const Rect.fromLTWH(724, 112, 222, 82),
      const Radius.circular(24),
    );
    canvas.drawRRect(totalPill, Paint()..color = palette.pill);
    _drawText(
      canvas,
      '$total',
      const Offset(748, 122),
      maxWidth: 174,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: palette.pillText,
        fontSize: 34,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
    _drawText(
      canvas,
      config.totalLabel,
      const Offset(748, 160),
      maxWidth: 174,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: palette.pillSubtext,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );

    final date = DateFormat.yMMMd(locale).format(DateTime.now());
    _drawText(
      canvas,
      'Album Collect 2026 - $date',
      const Offset(120, 198),
      maxWidth: 820,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );

    final gridBottom = _drawGrid(canvas, items, config, palette);

    if (hiddenCount > 0) {
      final moreRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(120, gridBottom + 26, 840, 60),
        const Radius.circular(18),
      );
      canvas.drawRRect(moreRect, Paint()..color = palette.moreBackground);
      _drawText(
        canvas,
        config.moreLabel?.call(hiddenCount) ??
            '+ $hiddenCount more stickers in your list',
        Offset(148, gridBottom + 42),
        maxWidth: 784,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: palette.moreText,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      );
    }

    _drawText(
      canvas,
      config.footer,
      Offset(120, size.height - 116),
      maxWidth: 840,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: palette.footerText,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }

  static double _drawGrid(
    Canvas canvas,
    List<ShareStickerListItem> items,
    ShareStickerListConfig config,
    _ShareImagePalette palette,
  ) {
    const left = 120.0;
    const top = 274.0;
    const width = 840.0;
    const gap = 16.0;
    const tileHeight = 92.0;
    const rowGap = 18.0;
    final columns = _normalizedColumns(config);
    final tileWidth = (width - (columns - 1) * gap) / columns;
    for (var i = 0; i < items.length; i++) {
      final col = i % columns;
      final row = i ~/ columns;
      final rect = Rect.fromLTWH(
        left + col * (tileWidth + gap),
        top + row * (tileHeight + rowGap),
        tileWidth,
        tileHeight,
      );
      _drawTile(canvas, rect, items[i], palette);
    }
    final rows = math.max(1, (items.length / columns).ceil());
    return top + rows * tileHeight + math.max(0, rows - 1) * rowGap;
  }

  static void _drawTile(
    Canvas canvas,
    Rect rect,
    ShareStickerListItem item,
    _ShareImagePalette imagePalette,
  ) {
    final palette = imagePalette.tilePalette(item.tone);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    canvas.drawRRect(rrect, Paint()..color = palette.background);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = palette.border,
    );

    final trailingText = item.trailingText;
    if (trailingText == null || trailingText.isEmpty) {
      _drawText(
        canvas,
        item.code,
        Offset(rect.left + 10, rect.top + 28),
        maxWidth: rect.width - 20,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: TextStyle(
          color: palette.primaryText,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      );
      return;
    }

    _drawText(
      canvas,
      item.code,
      Offset(rect.left + 10, rect.top + 20),
      maxWidth: rect.width - 20,
      textAlign: TextAlign.center,
      maxLines: 1,
      style: TextStyle(
        color: palette.primaryText,
        fontSize: 26,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
    _drawText(
      canvas,
      trailingText,
      Offset(rect.left + 10, rect.top + 52),
      maxWidth: rect.width - 20,
      textAlign: TextAlign.center,
      maxLines: 1,
      style: TextStyle(
        color: palette.secondaryText,
        fontSize: 21,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }

  static void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required TextStyle style,
    required double maxWidth,
    int maxLines = 2,
    TextAlign textAlign = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      textAlign: textAlign,
      maxLines: maxLines,
      ellipsis: '...',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  static List<ShareStickerListItem> _sortedItems(
    List<ShareStickerListItem> items,
  ) {
    return [...items]..sort((a, b) {
      final byTeam = a.teamCode.compareTo(b.teamCode);
      if (byTeam != 0) return byTeam;
      return a.code.compareTo(b.code);
    });
  }

  static int _itemsPerPage(ShareStickerListConfig config) =>
      _normalizedColumns(config) * gridRowsPerPage;

  static int _normalizedColumns(ShareStickerListConfig config) =>
      config.gridColumns.clamp(2, 6);
}

class _ShareImagePalette {
  const _ShareImagePalette({
    required this.backgroundStart,
    required this.backgroundMid,
    required this.backgroundEnd,
    required this.orb,
    required this.card,
    required this.topBand,
    required this.pill,
    required this.pillText,
    required this.pillSubtext,
    required this.footerText,
    required this.moreBackground,
    required this.moreText,
    required this.neutralTile,
    required this.ownedTile,
    required this.missingTile,
    required this.duplicateTile,
  });

  final Color backgroundStart;
  final Color backgroundMid;
  final Color backgroundEnd;
  final Color orb;
  final Color card;
  final Color topBand;
  final Color pill;
  final Color pillText;
  final Color pillSubtext;
  final Color footerText;
  final Color moreBackground;
  final Color moreText;
  final _StickerTilePalette neutralTile;
  final _StickerTilePalette ownedTile;
  final _StickerTilePalette missingTile;
  final _StickerTilePalette duplicateTile;

  factory _ShareImagePalette.fromColorScheme(ColorScheme scheme) {
    final primary = scheme.primary;
    final primaryDark = _mix(primary, Colors.black, 0.36);
    final primaryDarker = _mix(primary, Colors.black, 0.70);
    final primaryDeep = _mix(primary, Colors.black, 0.82);
    final primaryLight = _mix(primary, Colors.white, 0.62);
    final primaryPale = _mix(primary, Colors.white, 0.88);
    final primaryBarely = _mix(primary, Colors.white, 0.95);

    return _ShareImagePalette(
      backgroundStart: _mix(primary, Colors.black, 0.88),
      backgroundMid: primaryDeep,
      backgroundEnd: primaryDarker,
      orb: primaryLight,
      card: primaryBarely,
      topBand: primaryDark,
      pill: primaryLight,
      pillText: primaryDeep,
      pillSubtext: primaryDarker,
      footerText: _mix(primary, const Color(0xFF778897), 0.72),
      moreBackground: primaryPale,
      moreText: primaryDark,
      neutralTile: _StickerTilePalette(
        background: _mix(primary, Colors.white, 0.97),
        border: _mix(primary, Colors.white, 0.78),
        primaryText: primaryDark,
        secondaryText: _mix(primary, const Color(0xFF516A7D), 0.55),
      ),
      ownedTile: _StickerTilePalette(
        background: primaryPale,
        border: _mix(primary, Colors.white, 0.55),
        primaryText: primaryDarker,
        secondaryText: primaryDark,
      ),
      missingTile: const _StickerTilePalette(
        background: Color(0xFFF2F4F7),
        border: Color(0xFFD4DAE2),
        primaryText: Color(0xFF596473),
        secondaryText: Color(0xFF7B8490),
      ),
      duplicateTile: _StickerTilePalette(
        background: _mix(primary, Colors.white, 0.84),
        border: _mix(primary, Colors.white, 0.48),
        primaryText: primaryDark,
        secondaryText: _mix(primary, const Color(0xFF516A7D), 0.42),
      ),
    );
  }

  _StickerTilePalette tilePalette(ShareStickerTileTone tone) {
    return switch (tone) {
      ShareStickerTileTone.owned => ownedTile,
      ShareStickerTileTone.missing => missingTile,
      ShareStickerTileTone.duplicate => duplicateTile,
      ShareStickerTileTone.neutral => neutralTile,
    };
  }

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
}

class _StickerTilePalette {
  const _StickerTilePalette({
    required this.background,
    required this.border,
    required this.primaryText,
    required this.secondaryText,
  });

  final Color background;
  final Color border;
  final Color primaryText;
  final Color secondaryText;
}

String _teamCodeFromStickerId(String stickerId) {
  final idx = stickerId.indexOf('-');
  return idx > 0 ? stickerId.substring(0, idx) : stickerId;
}

String _shareTitleForSticker(String stickerId) {
  final sticker = WorldCup2026Seed.getStickerById(stickerId);
  if (sticker == null) return WorldCup2026Seed.stickerCaptionTitle(stickerId);
  final team = WorldCup2026Seed.getTeamById(sticker.teamId);
  final teamName = team?.name.tr() ?? sticker.teamId;
  return switch (sticker.type) {
    StickerType.badge => 'teamDetailTeamBadgeCountry'.tr(
      namedArgs: {'country': teamName},
    ),
    StickerType.team_photo => 'teamDetailTeamPhoto'.tr(),
    StickerType.player =>
      (sticker.playerName ?? '').trim().isNotEmpty
          ? sticker.playerName!.trim()
          : 'player'.tr(),
    StickerType.special => 'sticker'.tr(),
  };
}
