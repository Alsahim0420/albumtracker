import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

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
    if (_openAiService.isConfigured && Platform.isIOS) {
      return _processImageIos(imagePath);
    }

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

  Future<StickerScanPipelineResult> _processImageIos(String imagePath) async {
    final candidates = await _buildIosImageCandidates(imagePath);
    try {
      _ScoredPipelineResult? best;

      for (final candidatePath in candidates) {
        final text = await _openAiService.extractStickerTextFromImage(
          candidatePath,
          detail: 'high',
        );
        if (text.trim().isEmpty) continue;

        final pipeline = await _buildPipelineFromText(
          sourceImagePath: imagePath,
          textForResolve: text,
        );
        final score = _scorePipeline(pipeline);
        if (best == null || score > best.score) {
          best = _ScoredPipelineResult(score: score, result: pipeline);
        }
      }

      // Fallback fuerte para reverso: solo códigos XXX NN.
      if (best == null || best.result.matchedStickers.isEmpty) {
        for (final candidatePath in candidates) {
          final backCodes = await _openAiService.extractBackCodesFromImage(
            candidatePath,
            detail: 'high',
          );
          if (backCodes.trim().isEmpty) continue;
          final pipeline = await _buildPipelineFromText(
            sourceImagePath: imagePath,
            textForResolve: backCodes,
          );
          final score = _scorePipeline(pipeline) + 3.0;
          if (best == null || score > best.score) {
            best = _ScoredPipelineResult(score: score, result: pipeline);
          }
        }
      }

      if (best != null) return best.result;

      // Último fallback iOS: texto vacío para que el flujo no rompa.
      return _buildPipelineFromText(sourceImagePath: imagePath, textForResolve: '');
    } finally {
      await _cleanupTempCandidates(candidates, keep: imagePath);
    }
  }

  Future<StickerScanPipelineResult> _buildPipelineFromText({
    required String sourceImagePath,
    required String textForResolve,
  }) async {
    final rawTextForResult = textForResolve;
    final normalizedText = _ocrResolver.textParser.normalizeRawText(textForResolve);
    final full = await _ocrResolver.resolve(
      imagePath: sourceImagePath,
      rawOcrText: textForResolve,
    );
    final side = full.inferredSide;
    final stickers = full.resolvedStickers;
    final ocr = full.primaryDetection;
    final rejectedMatchLog = StickerMatcherService.takeRejectedMatchLog();
    if (kDebugMode) {
      final shortPath = sourceImagePath.split(RegExp(r'[/\\]')).last;
      debugPrint('[StickerScan][iOS] archivo: $shortPath');
      debugPrint('[StickerScan][iOS] texto normalizado (${normalizedText.length}):');
      debugPrint(normalizedText);
      debugPrint('[StickerScan][iOS] lado: $side | ocr: ${ocr.toJson()} | canAdd: ${full.canAutoAdd}');
      debugPrint(
        '[StickerScan][iOS] matches (${stickers.length}): ${stickers.map((s) => s.id).join(", ")}',
      );
      for (final line in rejectedMatchLog) {
        debugPrint('[StickerScan][iOS] rejectedMatch: $line');
      }
    }

    return StickerScanPipelineResult(
      imagePath: sourceImagePath,
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

  double _scorePipeline(StickerScanPipelineResult result) {
    final stickers = result.matchedStickers.length;
    final conf = result.ocrDetection.confidence;
    final text = result.normalizedText;
    final hasBackSignal =
        text.contains('FIFA') &&
        text.contains('WORLD') &&
        text.contains('CUP') &&
        text.contains('2026');

    var score = 0.0;
    score += stickers * 10.0;
    score += conf * 5.0;
    if (result.canAutoAdd) score += 2.0;
    if (result.side == StickerScanImageSide.back && stickers > 0) score += 4.0;
    if (hasBackSignal) score += 1.0;
    if (stickers == 0) score -= 8.0;
    return score;
  }

  Future<List<String>> _buildIosImageCandidates(String originalPath) async {
    final out = <String>[originalPath];
    try {
      final file = File(originalPath);
      if (!await file.exists()) return out;
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return out;

      final variants = <img.Image>[
        img.copyRotate(decoded, angle: 90),
        img.copyRotate(decoded, angle: -90),
      ];
      for (var i = 0; i < variants.length; i++) {
        final tmp = File(
          '${Directory.systemTemp.path}/albumtracker_ios_ocr_${DateTime.now().microsecondsSinceEpoch}_$i.jpg',
        );
        await tmp.writeAsBytes(img.encodeJpg(variants[i], quality: 92));
        out.add(tmp.path);
      }
    } catch (_) {
      // Si falla el preproceso, seguimos con original.
    }
    return out;
  }

  Future<void> _cleanupTempCandidates(
    List<String> paths, {
    required String keep,
  }) async {
    for (final p in paths) {
      if (p == keep) continue;
      try {
        final f = File(p);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }
}

class _ScoredPipelineResult {
  const _ScoredPipelineResult({required this.score, required this.result});
  final double score;
  final StickerScanPipelineResult result;
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
