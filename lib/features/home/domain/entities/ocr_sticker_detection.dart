import 'package:equatable/equatable.dart';

import 'package:albumtracker/core/models/sticker_model.dart';

/// Tipo lógico devuelto por el flujo OCR (puede ser `special` sin [StickerModel] en el seed).
enum OcrLogicalStickerType {
  badge,
  teamPhoto,
  player,
  special,
  unknown,
}

/// Origen de la señal usada para el resultado.
enum OcrDetectionSource {
  backText,
  frontText,
  /// Varios jugadores resueltos por nombre en una misma imagen frontal.
  playerMatch,
  shieldMatch,
  manualReview,
  specialDetection,
  legacyBack,
  legacyFront,
  combined,
}

class OcrStickerDetection extends Equatable {
  const OcrStickerDetection({
    this.countryCode,
    this.stickerNumber,
    this.code,
    this.type = OcrLogicalStickerType.unknown,
    this.confidence = 0.0,
    this.detectionSource = OcrDetectionSource.manualReview,
    this.needsManualReview = true,
    this.specialCategory,
    this.specialCode,
  });

  final String? countryCode;
  final int? stickerNumber;
  /// p. ej. "POR 11"
  final String? code;
  final OcrLogicalStickerType type;
  final double confidence;
  final OcrDetectionSource detectionSource;
  final bool needsManualReview;
  final String? specialCategory;
  final String? specialCode;

  Map<String, Object?> toJson() => {
    'countryCode': countryCode,
    'stickerNumber': stickerNumber,
    'code': code,
    'type': type.name,
    'confidence': confidence,
    'detectionSource': detectionSource.name,
    'needsManualReview': needsManualReview,
    'specialCategory': specialCategory,
    'specialCode': specialCode,
  };

  OcrStickerDetection copyWith({
    String? countryCode,
    int? stickerNumber,
    String? code,
    OcrLogicalStickerType? type,
    double? confidence,
    OcrDetectionSource? detectionSource,
    bool? needsManualReview,
    String? specialCategory,
    String? specialCode,
  }) {
    return OcrStickerDetection(
      countryCode: countryCode ?? this.countryCode,
      stickerNumber: stickerNumber ?? this.stickerNumber,
      code: code ?? this.code,
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      detectionSource: detectionSource ?? this.detectionSource,
      needsManualReview: needsManualReview ?? this.needsManualReview,
      specialCategory: specialCategory ?? this.specialCategory,
      specialCode: specialCode ?? this.specialCode,
    );
  }

  @override
  List<Object?> get props => [
    countryCode,
    stickerNumber,
    code,
    type,
    confidence,
    detectionSource,
    needsManualReview,
    specialCategory,
    specialCode,
  ];

  static OcrLogicalStickerType fromStickerModelType(StickerType t) {
    switch (t) {
      case StickerType.badge:
        return OcrLogicalStickerType.badge;
      case StickerType.team_photo:
        return OcrLogicalStickerType.teamPhoto;
      case StickerType.player:
        return OcrLogicalStickerType.player;
      case StickerType.special:
        return OcrLogicalStickerType.special;
    }
  }
}
