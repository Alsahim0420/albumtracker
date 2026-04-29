import 'fifa_2026_back_ocr_parser.dart';

/// Láminas de colección que no siguen el esquema país 1-20: sin forzar id inventados.
class SpecialStickerOcrHeuristic {
  /// [normalizedUpper] = [StickerTextParser] style.
  static bool looksLikeSpecialUnnumberedAlbumSticker(String normalizedUpper) {
    if (Fifa2026BackOcrParser.isFifaWorldCup2026BackText(normalizedUpper) &&
        Fifa2026BackOcrParser.extractFifaStyleCodes(normalizedUpper).isNotEmpty) {
      return false;
    }
    if (Fifa2026BackOcrParser.extractFifaStyleCodes(normalizedUpper).isNotEmpty) {
      return false;
    }
    final t = normalizedUpper;
    for (final k in _strongKeywords) {
      if (t.contains(k)) return true;
    }
    return false;
  }

  static const _strongKeywords = <String>[
    'STADIUM FOL',
    'STADIUMS',
    'MOMENT',
    'HISTORY OF',
  ];
}
