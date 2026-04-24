import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/models/sticker_model.dart';

/// Matching de frente: nombres del OCR frente al plantel + [StickerModel.teamId].
class FrontStickerMatcher {
  /// Palabras muy comunes (neerlandés / ruido) que no deben resolver un jugador solas.
  static const _noiseTokens = {
    'van',
    'de',
    'den',
    'het',
    'ter',
    'ten',
    'voor',
    'der',
    'von',
    'und',
    'the',
    'and',
  };

  /// Todas las láminas distintas detectables en el texto.
  ///
  /// Si el OCR incluye varios jugadores del **mismo** equipo pero **no** lee el código
  /// FIFA (NED, ARG…), se confía en el consenso de nombres y no se exige `NED` en texto.
  ///
  /// Además, si hay consenso de equipo, se intentan coincidencias por **fragmentos**
  /// únicos del nombre (p. ej. `meiners` → Teun Koopmeiners, `ligt` → Matthijs de Ligt)
  /// cuando el OCR parte o tuerce el nombre completo.
  List<StickerModel> matchAllWithCountryInText(String rawOcrText) {
    final upper = rawOcrText.toUpperCase();
    final primary = WorldCup2026Seed.findStickersByPlayerNamesInText(rawOcrText);

    final merged = <String, StickerModel>{for (final s in primary) s.id: s};

    final primaryTeams = primary.map((s) => s.teamId).toSet();
    if (primary.isNotEmpty && primaryTeams.length == 1) {
      final tid = primaryTeams.single;
      if (tid.length == 3) {
        for (final s in _supplementByUniqueTokensForTeam(tid, rawOcrText, merged.keys.toSet())) {
          merged[s.id] = s;
        }
      }
    }

    if (merged.isEmpty) return [];

    final candidates = merged.values.toList();
    final uniqueTeams = candidates.map((s) => s.teamId).toSet();
    final singleTeamInBatch = uniqueTeams.length == 1;

    final out = <StickerModel>[];
    final seen = <String>{};

    for (final s in candidates) {
      final tid = s.teamId;
      if (tid.length != 3) continue;

      if (!singleTeamInBatch) {
        if (!RegExp(r'\b' + RegExp.escape(tid) + r'\b').hasMatch(upper)) {
          continue;
        }
      }

      if (seen.add(s.id)) out.add(s);
    }

    out.sort((a, b) {
      final ga = a.globalNumber ?? 1 << 30;
      final gb = b.globalNumber ?? 1 << 30;
      final c = ga.compareTo(gb);
      if (c != 0) return c;
      return a.id.compareTo(b.id);
    });
    return out;
  }

  /// Para un equipo ya inferido: palabras del OCR que encajan en un solo jugador del plantel.
  List<StickerModel> _supplementByUniqueTokensForTeam(
    String teamId,
    String rawOcrText,
    Set<String> alreadyMatchedIds,
  ) {
    final team = WorldCup2026Seed.getTeamById(teamId);
    if (team == null) return [];

    final blob = WorldCup2026Seed.normalizeTextForPlayerNameMatch(rawOcrText);
    if (blob.length < 4) return [];

    final words = blob.split(' ').where((w) => w.length >= 4).toList();
    final players = team.stickers.where((s) => s.type == StickerType.player).toList();

    final added = <StickerModel>[];

    for (final w in words) {
      if (_noiseTokens.contains(w)) continue;

      final hits = <StickerModel>[];
      for (final s in players) {
        if (alreadyMatchedIds.contains(s.id)) continue;
        if (added.any((x) => x.id == s.id)) continue;
        final pn = WorldCup2026Seed.normalizeTextForPlayerNameMatch(
          s.playerName ?? '',
        );
        if (pn.length < 4) continue;
        if (pn.contains(w)) hits.add(s);
      }

      if (hits.length == 1) added.add(hits.first);
    }

    return added;
  }
}
