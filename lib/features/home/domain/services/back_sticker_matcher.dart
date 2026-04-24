import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/features/home/domain/services/back_sticker_code_parser.dart';

/// Matching de reverso: solo el primer código estructurado que resuelva a una lámina del seed.
class BackStickerMatcher {
  BackStickerMatcher({BackStickerCodeParser? parser})
    : _parser = parser ?? BackStickerCodeParser();

  final BackStickerCodeParser _parser;

  StickerModel? matchSingle(String normalizedUpperText) {
    for (final code in _parser.extractStructuredCodes(normalizedUpperText)) {
      final s = WorldCup2026Seed.getStickerByFlexibleIdentifier(code);
      if (s != null) return s;
    }
    return null;
  }
}
