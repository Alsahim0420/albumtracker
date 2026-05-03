import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/models/sticker_model.dart';

class StickerMatcherService {
  StickerModel? findBestMatch(List<String> candidates) {
    for (final candidate in candidates) {
      final sticker = WorldCup2026Seed.getStickerByFlexibleIdentifier(
        candidate,
      );
      if (sticker != null) return sticker;
    }
    return null;
  }

  /// Todas las láminas distintas que coincidan con algún candidato (una foto puede
  /// incluir varias láminas, p. ej. rejilla en una sola imagen).
  ///
  /// [rawOcrText]: texto completo del OCR; si se pasa, también busca por nombre de
  /// jugador (foto frontal con "LIONEL MESSI", etc.) contra el seed actual.
  List<StickerModel> findAllDistinctMatches(
    List<String> candidates, {
    String? rawOcrText,
  }) {
    final byId = <String, StickerModel>{};
    for (final candidate in candidates) {
      final sticker = WorldCup2026Seed.getStickerByFlexibleIdentifier(
        candidate,
      );
      if (sticker != null) {
        byId[sticker.id] = sticker;
      }
    }
    if (rawOcrText != null && rawOcrText.isNotEmpty) {
      for (final sticker in WorldCup2026Seed.findStickersByPlayerNamesInText(
        rawOcrText,
      )) {
        byId[sticker.id] = sticker;
      }
    }
    return byId.values.toList(growable: false);
  }
}
