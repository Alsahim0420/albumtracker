import 'package:flutter/foundation.dart';

import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/core/services/openai_service.dart';
import 'package:albumtracker/features/home/data/services/sticker_ocr_service.dart';
import 'package:albumtracker/features/home/domain/entities/ocr_sticker_detection.dart';
import 'package:albumtracker/features/home/domain/entities/sticker_scan_image_side.dart';
import 'package:albumtracker/features/home/domain/services/sticker_matcher_service.dart';
import 'package:albumtracker/features/home/domain/services/sticker_ocr_resolver.dart';

/// Orquesta captura → texto → resolver.
///
/// Con API key OpenAI: **solo visión GPT** (imagen → texto), sin ML Kit.
/// Si GPT devuelve vacío o error, no hay respaldo OCR: se resuelve con texto vacío.
/// Sin clave: ML Kit como única fuente de texto.
/// El texto pasa al mismo [StickerOcrResolver]: si hay varias apariciones
/// del mismo jugador/código en el texto, el matcher puede devolver el mismo id varias veces
/// y el use case suma cada una al álbum.
/// Frente: puede devolver varias láminas; reverso: según resolución actual.
class StickerScanCoordinator {
  StickerScanCoordinator({
    required StickerOcrService ocrService,
    required StickerOcrResolver ocrResolver,
    required OpenAIService openAiService,
  }) : _ocrService = ocrService,
       _ocrResolver = ocrResolver,
       _openAiService = openAiService;

  final StickerOcrService _ocrService;
  final StickerOcrResolver _ocrResolver;
  final OpenAIService _openAiService;

  Future<StickerScanPipelineResult> processImage(String imagePath) async {
    String textForResolve;
    String rawTextForResult;
    if (_openAiService.isConfigured) {
      textForResolve = await _openAiService.extractStickerTextFromImage(imagePath);
      rawTextForResult = textForResolve;
      if (textForResolve.trim().isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[StickerScan] GPT visión vacío o error; sin respaldo ML Kit (solo IA)',
          );
        }
      } else if (kDebugMode) {
        debugPrint(
          '[StickerScan] texto desde GPT visión (${textForResolve.length} caracteres)',
        );
      }
    } else {
      if (kDebugMode) {
        debugPrint('[StickerScan] Sin OPENAI_API_KEY; usando ML Kit');
      }
      textForResolve = await _ocrService.extractText(imagePath);
      rawTextForResult = textForResolve;
    }
    final normalizedText = _ocrResolver.textParser.normalizeRawText(textForResolve);
    final full = await _ocrResolver.resolve(
      imagePath: imagePath,
      rawOcrText: textForResolve,
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
      debugPrint('[StickerScan] finalMatchesCount=${stickers.length}');
      debugPrint(
        '[StickerScan] finalMatchesIdsWithDuplicates=${stickers.map((s) => s.id).join(", ")}',
      );
      for (final line in rejectedMatchLog) {
        debugPrint('[StickerScan] rejectedMatch: $line');
      }
    }

    return StickerScanPipelineResult(
      imagePath: imagePath,
      rawText: rawTextForResult,
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
