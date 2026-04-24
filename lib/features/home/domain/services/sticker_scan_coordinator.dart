import 'package:flutter/foundation.dart';

import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/features/home/data/services/sticker_ocr_service.dart';
import 'package:albumtracker/features/home/domain/entities/sticker_scan_image_side.dart';
import 'package:albumtracker/features/home/domain/services/back_sticker_matcher.dart';
import 'package:albumtracker/features/home/domain/services/front_sticker_matcher.dart';
import 'package:albumtracker/features/home/domain/services/sticker_image_side_detector.dart';
import 'package:albumtracker/features/home/domain/services/sticker_text_parser.dart';

/// Orquesta OCR → lado → estrategia.
/// Frente: puede devolver varias láminas (rejilla / varios jugadores en una foto).
/// Reverso: como mucho una lámina por imagen.
class StickerScanCoordinator {
  StickerScanCoordinator({
    required StickerOcrService ocrService,
    required StickerTextParser textParser,
    required StickerImageSideDetector sideDetector,
    required FrontStickerMatcher frontMatcher,
    required BackStickerMatcher backMatcher,
  }) : _ocrService = ocrService,
       _textParser = textParser,
       _sideDetector = sideDetector,
       _frontMatcher = frontMatcher,
       _backMatcher = backMatcher;

  final StickerOcrService _ocrService;
  final StickerTextParser _textParser;
  final StickerImageSideDetector _sideDetector;
  final FrontStickerMatcher _frontMatcher;
  final BackStickerMatcher _backMatcher;

  Future<StickerScanPipelineResult> processImage(String imagePath) async {
    final rawText = await _ocrService.extractText(imagePath);
    final normalizedText = _textParser.normalizeRawText(rawText);
    final side = _sideDetector.detect(
      rawOcrText: rawText,
      normalizedUpperText: normalizedText,
    );

    if (kDebugMode) {
      final shortPath = imagePath.split(RegExp(r'[/\\]')).last;
      debugPrint('[StickerScan] archivo: $shortPath');
      debugPrint('[StickerScan] texto normalizado (${normalizedText.length}):');
      debugPrint(normalizedText);
      debugPrint('[StickerScan] lado detectado: $side');
    }

    switch (side) {
      case StickerScanImageSide.front:
        final stickers = _frontMatcher.matchAllWithCountryInText(rawText);
        if (kDebugMode) {
          debugPrint(
            '[StickerScan] match frente (${stickers.length}): '
            '${stickers.map((s) => s.id).join(", ")}',
          );
        }
        return StickerScanPipelineResult(
          imagePath: imagePath,
          rawText: rawText,
          normalizedText: normalizedText,
          side: side,
          matchedStickers: stickers,
          detectedHint: stickers.isEmpty ? null : stickers.first.code,
        );
      case StickerScanImageSide.back:
        final sticker = _backMatcher.matchSingle(normalizedText);
        if (kDebugMode) {
          debugPrint(
            '[StickerScan] match reverso: ${sticker?.id ?? "ninguno"} '
            '(${sticker?.code ?? "-"})',
          );
        }
        return StickerScanPipelineResult(
          imagePath: imagePath,
          rawText: rawText,
          normalizedText: normalizedText,
          side: side,
          matchedStickers: sticker != null ? [sticker] : [],
          detectedHint: sticker?.code,
        );
      case StickerScanImageSide.unknown:
        if (kDebugMode) {
          debugPrint('[StickerScan] lado desconocido → sin match automático');
        }
        return StickerScanPipelineResult(
          imagePath: imagePath,
          rawText: rawText,
          normalizedText: normalizedText,
          side: side,
          matchedStickers: [],
          detectedHint: null,
        );
    }
  }
}

class StickerScanPipelineResult {
  const StickerScanPipelineResult({
    required this.imagePath,
    required this.rawText,
    required this.normalizedText,
    required this.side,
    required this.matchedStickers,
    required this.detectedHint,
  });

  final String imagePath;
  final String rawText;
  final String normalizedText;
  final StickerScanImageSide side;
  /// Frente: cero o más. Reverso: cero o uno.
  final List<StickerModel> matchedStickers;
  final String? detectedHint;
}
