import 'package:equatable/equatable.dart';

import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/features/home/domain/entities/ocr_sticker_detection.dart';
import 'package:albumtracker/features/home/domain/entities/sticker_scan_image_side.dart';

enum StickerScanStatus {
  added,
  alreadyExists,
  notFound,
  ocrFailed,
  error,
  /// Confianza baja o lámina no resuelta: no se modifica la colección.
  needsManualReview,
}

class SingleStickerScanResult extends Equatable {
  const SingleStickerScanResult({
    required this.imagePath,
    required this.rawText,
    required this.normalizedText,
    required this.detectedIdentifier,
    required this.matchedSticker,
    required this.status,
    required this.message,
    this.imageSide,
    this.ocrDetection,
  });

  final String imagePath;
  final String rawText;
  final String normalizedText;
  final String? detectedIdentifier;
  final StickerModel? matchedSticker;
  final StickerScanStatus status;
  final String message;
  /// Lado inferido (frente/reverso/desconocido); null si falló OCR antes de clasificar.
  final StickerScanImageSide? imageSide;
  final OcrStickerDetection? ocrDetection;

  @override
  List<Object?> get props => [
    imagePath,
    rawText,
    normalizedText,
    detectedIdentifier,
    matchedSticker?.id,
    status,
    message,
    imageSide,
    ocrDetection,
  ];
}

class BatchStickerScanResult extends Equatable {
  const BatchStickerScanResult({
    required this.total,
    required this.processedStickerCount,
    required this.added,
    required this.alreadyOwned,
    required this.notFound,
    required this.failed,
    required this.needsManualReview,
    required this.items,
  });

  /// Filas en [items] (éxitos, fallos, no encontrado, etc.).
  final int total;

  /// Láminas válidas detectadas y aplicadas a la colección (nuevas + repetidas).
  final int processedStickerCount;

  final int added;
  final int alreadyOwned;
  final int notFound;
  final int failed;
  final int needsManualReview;
  final List<SingleStickerScanResult> items;

  @override
  List<Object?> get props => [
    total,
    processedStickerCount,
    added,
    alreadyOwned,
    notFound,
    failed,
    needsManualReview,
    items,
  ];
}
