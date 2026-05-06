import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/features/home/domain/entities/ai_image_analysis_result.dart';
import 'package:albumtracker/features/home/domain/entities/ocr_sticker_detection.dart';
import 'package:albumtracker/features/home/domain/entities/sticker_scan_image_side.dart';
import 'package:albumtracker/features/home/domain/repositories/image_analysis_repository.dart';
import 'package:albumtracker/features/home/domain/services/ai_analysis_to_seed_matcher.dart';

/// Orquesta el escaneo remoto (backend IA) y el matching al seed local.
class StickerScanCoordinator {
  StickerScanCoordinator({
    required ImageAnalysisRepository imageAnalysisRepository,
    required AiAnalysisToSeedMatcher aiMatcher,
  }) : _imageAnalysisRepository = imageAnalysisRepository,
       _aiMatcher = aiMatcher;

  final ImageAnalysisRepository _imageAnalysisRepository;
  final AiAnalysisToSeedMatcher _aiMatcher;

  Future<StickerScanPipelineResult> processImage(String imagePath) async {
    final analysis = await _imageAnalysisRepository.analyzeImage(imagePath);
    final match = _aiMatcher.match(analysis.stickers);
    final normalizedText = _buildNormalizedText(match.rawTexts);
    final side = _toImageSide(analysis.imageSide);
    final ocr = _buildDetectionFromAnalysis(analysis, match);

    return StickerScanPipelineResult(
      imagePath: imagePath,
      rawText: match.rawTexts.join('\n'),
      normalizedText: normalizedText,
      side: side,
      matchedStickers: match.matchedStickers,
      canAutoAdd: match.matchedStickers.isNotEmpty,
      ocrDetection: ocr,
      detectedHint: match.primaryStickerCode,
      warnings: [...analysis.warnings, ...match.warnings],
    );
  }

  String _buildNormalizedText(List<String> rawTexts) {
    final lines = rawTexts.map((e) => e.trim()).where((e) => e.isNotEmpty);
    return lines.join(' ').toUpperCase();
  }

  StickerScanImageSide _toImageSide(String imageSide) {
    switch (imageSide.trim().toLowerCase()) {
      case 'front':
        return StickerScanImageSide.front;
      case 'back':
        return StickerScanImageSide.back;
      default:
        return StickerScanImageSide.unknown;
    }
  }

  OcrStickerDetection _buildDetectionFromAnalysis(
    AiImageAnalysisResult analysis,
    AiSeedMatchResult match,
  ) {
    final first = analysis.stickers.isEmpty ? null : analysis.stickers.first;
    final matchedFirst = match.matchedStickers.isEmpty ? null : match.matchedStickers.first;
    return OcrStickerDetection(
      countryCode: first?.countryCode ?? matchedFirst?.teamId,
      stickerNumber: first?.number ?? matchedFirst?.localNumber,
      code: first?.stickerCode ?? matchedFirst?.code,
      type: _toLogicalType(first?.type),
      confidence: first?.confidence ?? 0.0,
      detectionSource: OcrDetectionSource.combined,
      needsManualReview: false,
    );
  }

  OcrLogicalStickerType _toLogicalType(String? type) {
    switch (type?.toLowerCase()) {
      case 'player':
        return OcrLogicalStickerType.player;
      case 'badge':
        return OcrLogicalStickerType.badge;
      case 'special':
        return OcrLogicalStickerType.special;
      default:
        return OcrLogicalStickerType.unknown;
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
    required this.canAutoAdd,
    required this.ocrDetection,
    required this.detectedHint,
    this.rejectedMatchLog = const [],
    this.warnings = const [],
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
  /// Advertencias del backend IA y del matcher local.
  final List<String> warnings;
}
