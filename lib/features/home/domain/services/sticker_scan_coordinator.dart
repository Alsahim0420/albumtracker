import 'package:flutter/foundation.dart';

import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/features/home/data/services/sticker_ocr_service.dart';
import 'package:albumtracker/features/home/domain/entities/ocr_sticker_detection.dart';
import 'package:albumtracker/features/home/domain/entities/sticker_scan_image_side.dart';
import 'package:albumtracker/features/home/domain/services/sticker_matcher_service.dart';
import 'package:albumtracker/features/home/domain/services/sticker_ocr_resolver.dart';

/// Orquesta OCR → lado → estrategia.
/// Frente: puede devolver varias láminas (rejilla / varios jugadores en una foto).
/// Reverso: como mucho una lámina por imagen.
class StickerScanCoordinator {
  StickerScanCoordinator({
    required StickerOcrService ocrService,
    required StickerOcrResolver ocrResolver,
  }) : _ocrService = ocrService,
       _ocrResolver = ocrResolver;

  final StickerOcrService _ocrService;
  final StickerOcrResolver _ocrResolver;

  Future<StickerScanPipelineResult> processImage(String imagePath) async {
    final rawText = await _ocrService.extractText(imagePath);
    final normalizedText = _ocrResolver.textParser.normalizeRawText(rawText);
    final full = await _ocrResolver.resolve(
      imagePath: imagePath,
      rawOcrText: rawText,
    );
    final side = full.inferredSide;
    final stickers = full.resolvedStickers;
    final ocr = full.primaryDetection;
    final rejectedMatchLog = StickerMatcherService.takeRejectedMatchLog();
    if (kDebugMode) {
      final shortPath = imagePath.split(RegExp(r'[/\\]')).last;
      debugPrint('[StickerScan] archivo: $shortPath');
      debugPrint('[StickerScan] texto normalizado (${normalizedText.length}):');
      debugPrint(normalizedText);
      debugPrint('[StickerScan] lado: $side | ocr: ${ocr.toJson()} | canAdd: ${full.canAutoAdd}');
      debugPrint(
        '[StickerScan] matches (${stickers.length}): ${stickers.map((s) => s.id).join(", ")}',
      );
      for (final line in rejectedMatchLog) {
        debugPrint('[StickerScan] rejectedMatch: $line');
      }
    }

    return StickerScanPipelineResult(
      imagePath: imagePath,
      rawText: rawText,
      normalizedText: normalizedText,
      side: side,
      matchedStickers: stickers,
      canAutoAdd: full.canAutoAdd,
      ocrDetection: ocr,
      detectedHint: ocr.code ?? (stickers.isNotEmpty ? stickers.first.code : null),
      rejectedMatchLog: rejectedMatchLog,
    );
  }
}

class StickerScanPipelineResult {
  const StickerScanPipelineResult({
    required this.imagePath,
    required this.rawText,
    required this.normalizedText,
    required this.side,
    required this.matchedStickers,
    required this.canAutoAdd,
    required this.ocrDetection,
    required this.detectedHint,
    this.rejectedMatchLog = const [],
  });

  final String imagePath;
  final String rawText;
  final String normalizedText;
  final StickerScanImageSide side;
  /// Frente: cero o más. Reverso: cero o uno.
  final List<StickerModel> matchedStickers;
  final bool canAutoAdd;
  final OcrStickerDetection ocrDetection;
  final String? detectedHint;
  /// Líneas de depuración: candidatos descartados (p. ej. país de club vs. lámina).
  final List<String> rejectedMatchLog;
}
