import 'package:equatable/equatable.dart';

import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/features/home/domain/entities/sticker_scan_image_side.dart';

enum StickerScanStatus { added, alreadyExists, notFound, ocrFailed, error }

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
  ];
}

class BatchStickerScanResult extends Equatable {
  const BatchStickerScanResult({
    required this.total,
    required this.added,
    required this.alreadyOwned,
    required this.notFound,
    required this.failed,
    required this.items,
  });

  final int total;
  final int added;
  final int alreadyOwned;
  final int notFound;
  final int failed;
  final List<SingleStickerScanResult> items;

  @override
  List<Object?> get props => [
    total,
    added,
    alreadyOwned,
    notFound,
    failed,
    items,
  ];
}
