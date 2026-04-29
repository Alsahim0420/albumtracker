import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/models/sticker_model.dart';

/// Matching de frente: nombres del OCR frente al plantel + [StickerModel.teamId].
class FrontStickerMatcher {
  static const double _autoAddThreshold = 0.85;
  static const double _topDeltaThreshold = 0.12;

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
    'di',
    'el',
    'al',
    'jr',
    'sa',
  };

  static Map<String, int>? _tokenFrequencyAcrossPlayers;

  /// Todas las láminas distintas detectables en el texto.
  ///
  /// Si el OCR incluye varios jugadores del **mismo** equipo pero **no** lee el código
  /// código de equipo (NED, ARG…), se confía en el consenso de nombres y no se exige `NED` en texto.
  ///
  /// Además, si hay consenso de equipo, se intentan coincidencias por **fragmentos**
  /// únicos del nombre (p. ej. `meiners` → Teun Koopmeiners, `ligt` → Matthijs de Ligt)
  /// cuando el OCR parte o tuerce el nombre completo.
  List<StickerModel> matchAllWithCountryInText(String rawOcrText) {
    final normalizedBlob = WorldCup2026Seed.normalizeTextForPlayerNameMatch(
      rawOcrText,
    );
    if (normalizedBlob.isEmpty) return [];

    _ensureTokenFrequencyAcrossPlayers();
    final teamHints = _buildTeamHints(rawOcrText);
    final players = _allPlayerStickers();
    final lines = _extractCandidateLines(rawOcrText);
    final byId = <String, StickerModel>{};

    // 1) Match fuerte por nombre completo en todo el blob OCR.
    final strict = WorldCup2026Seed.findStickersByPlayerNamesInText(rawOcrText);
    for (final s in strict) {
      byId[s.id] = s;
    }

    // 2) Match flexible por línea OCR: umbral + diferencia top1 vs top2.
    for (final line in lines) {
      final ranked = <_ScoredCandidate>[];
      for (final player in players) {
        final score = _scorePlayerLineMatch(
          line: line,
          player: player,
          teamHints: teamHints,
        );
        if (score > 0) {
          ranked.add(_ScoredCandidate(player: player, score: score));
        }
      }
      if (ranked.isEmpty) continue;
      ranked.sort((a, b) => b.score.compareTo(a.score));
      final top = ranked.first;
      final second = ranked.length > 1 ? ranked[1] : null;
      final delta = second == null ? 1.0 : (top.score - second.score);
      if (top.score >= _autoAddThreshold && delta >= _topDeltaThreshold) {
        byId[top.player.id] = top.player;
      }
    }

    // 3) Consenso de equipo (si hay >=2 del mismo team): sumar candidatos cercanos.
    final teamCounts = <String, int>{};
    for (final s in byId.values) {
      teamCounts.update(s.teamId, (v) => v + 1, ifAbsent: () => 1);
    }
    final consensusTeams = teamCounts.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .toSet();
    if (consensusTeams.isNotEmpty) {
      for (final line in lines) {
        for (final player in players.where(
          (p) => consensusTeams.contains(p.teamId) && !byId.containsKey(p.id),
        )) {
          final score = _scorePlayerLineMatch(
            line: line,
            player: player,
            teamHints: teamHints,
          );
          if (score >= (_autoAddThreshold - 0.05)) {
            byId[player.id] = player;
          }
        }
      }
    }

    // 4) Fallback de collage: si ya hubo varias detecciones, permitir agregar
    // jugadores por apellido largo/único detectado en el bloque OCR global.
    // Esto cubre OCR tipo "GUARDIOL" vs "GVARDIOL".
    if (byId.length >= 4) {
      final blobWords = normalizedBlob
          .split(' ')
          .where((w) => w.length >= 4)
          .toSet()
          .toList(growable: false);
      for (final player in players.where((p) => !byId.containsKey(p.id))) {
        final playerName = WorldCup2026Seed.normalizeTextForPlayerNameMatch(
          player.playerName ?? '',
        );
        if (playerName.isEmpty) continue;
        final nameWords = playerName
            .split(' ')
            .where((w) => w.length >= 4 && !_noiseTokens.contains(w))
            .toList(growable: false);
        if (nameWords.isEmpty) continue;

        final longUniqueWords = nameWords
            .where((w) => w.length >= 7 && !_isAmbiguousToken(w))
            .toList(growable: false);
        if (longUniqueWords.isEmpty) continue;

        final hasStrongSurnameHit = longUniqueWords.any((nw) {
          for (final bw in blobWords) {
            if (_normalizedSimilarity(nw, bw) >= 0.9) {
              return true;
            }
          }
          return false;
        });
        if (!hasStrongSurnameHit) continue;

        byId[player.id] = player;
      }
    }

    final out = byId.values.toList(growable: false);
    out.sort((a, b) {
      final ga = a.globalNumber ?? 1 << 30;
      final gb = b.globalNumber ?? 1 << 30;
      final c = ga.compareTo(gb);
      if (c != 0) return c;
      return a.id.compareTo(b.id);
    });
    return out;
  }

  /// Fallback de alta tolerancia para OCR sucio de una sola lámina frontal.
  /// Retorna un único jugador cuando el top es claramente mejor que el segundo.
  StickerModel? matchSingleBestEffort(String rawOcrText) {
    final players = _allPlayerStickers();
    final lines = _extractCandidateLines(rawOcrText);
    if (lines.isEmpty) return null;
    final teamHints = _buildTeamHints(rawOcrText);
    final bestByPlayer = <String, _ScoredCandidate>{};

    for (final line in lines) {
      for (final player in players) {
        final score = _scorePlayerLineMatch(
          line: line,
          player: player,
          teamHints: teamHints,
        );
        if (score <= 0) continue;
        final prev = bestByPlayer[player.id];
        if (prev == null || score > prev.score) {
          bestByPlayer[player.id] = _ScoredCandidate(player: player, score: score);
        }
      }
    }

    final ranked = bestByPlayer.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    if (ranked.isEmpty) return null;
    final top = ranked.first;
    final second = ranked.length > 1 ? ranked[1] : null;
    final delta = second == null ? 1.0 : (top.score - second.score);

    // Umbral relajado para casos tipo MOHAMIMED/MOHAMMED.
    if (top.score >= 0.55 && delta >= 0.20) {
      return top.player;
    }
    return null;
  }

  List<String> _extractCandidateLines(String rawOcrText) {
    final out = <String>{};
    for (final line in rawOcrText.split('\n')) {
      final normalized = WorldCup2026Seed.normalizeTextForPlayerNameMatch(line);
      if (normalized.length < 5) continue;
      out.add(normalized);
    }
    return out.toList(growable: false);
  }

  List<StickerModel> _allPlayerStickers() {
    final out = <StickerModel>[];
    for (final g in WorldCup2026Seed.groups) {
      for (final t in g.teams) {
        out.addAll(t.stickers.where((s) => s.type == StickerType.player));
      }
    }
    return out;
  }

  Map<String, _TeamHint> _buildTeamHints(String rawOcrText) {
    final upper = rawOcrText.toUpperCase();
    final tokens = RegExp(r'[A-Z]{3,4}')
        .allMatches(upper)
        .map((m) => m.group(0)!)
        .toList(growable: false);
    final out = <String, _TeamHint>{};

    for (final g in WorldCup2026Seed.groups) {
      for (final t in g.teams) {
        final tid = t.id.toUpperCase();
        if (tid.length != 3) continue;
        final exact = RegExp(r'\b' + RegExp.escape(tid) + r'\b').hasMatch(upper);
        final fuzzy = !exact &&
            tokens.any((tk) => _looksLikeTeamCode(tid: tid, token: tk));
        if (exact || fuzzy) {
          out[tid] = _TeamHint(exact: exact, fuzzy: fuzzy);
        }
      }
    }
    return out;
  }

  bool _looksLikeTeamCode({required String tid, required String token}) {
    if (token == tid) return true;
    if (token.length == 4 && (token.startsWith(tid) || token.endsWith(tid))) {
      return true;
    }
    if (token.length != 3) return false;
    return _levenshteinDistance(token, tid) <= 1;
  }

  double _scorePlayerLineMatch({
    required String line,
    required StickerModel player,
    required Map<String, _TeamHint> teamHints,
  }) {
    final playerName = WorldCup2026Seed.normalizeTextForPlayerNameMatch(
      player.playerName ?? '',
    );
    if (playerName.length < 4) return 0;

    final lineWords = line.split(' ').where((w) => w.isNotEmpty).toList();
    final nameWords = playerName
        .split(' ')
        .where((w) => w.length >= 2 && !_noiseTokens.contains(w))
        .toList();
    if (nameWords.isEmpty || lineWords.isEmpty) return 0;

    var strongHits = 0;
    var mediumHits = 0;
    var bestSingleToken = 0.0;
    var bestSingleTokenWord = '';
    var simSum = 0.0;

    for (final nw in nameWords) {
      var best = 0.0;
      for (final lw in lineWords) {
        final s = _normalizedSimilarity(nw, lw);
        if (s > best) best = s;
      }
      if (best >= 0.88) {
        strongHits++;
      } else if (best >= 0.78 && nw.length >= 4) {
        // OCR de fotos suele cambiar 1 letra: YERRY->VERRY, AYOUB->AVOUB.
        mediumHits++;
      }
      if (best > bestSingleToken) {
        bestSingleToken = best;
        bestSingleTokenWord = nw;
      }
      simSum += best;
    }

    final coverage = strongHits / nameWords.length;
    final avgSim = simSum / nameWords.length;
    final fullSim = _normalizedSimilarity(playerName, line);

    double score = 0.0;
    if (line.contains(playerName) || fullSim >= 0.95) {
      score += 0.75;
    } else if (coverage >= 0.8 && avgSim >= 0.88) {
      score += 0.60;
    } else if (strongHits >= 1 &&
        mediumHits >= 1 &&
        nameWords.length >= 2 &&
        avgSim >= 0.76) {
      // Caso nombres de 2+ tokens con una palabra bien y otra "casi" por OCR.
      // Ej.: "VERRY MINA" vs "YERRY MINA", "AVOUB EL KAABI" vs "AYOUB EL KAABI".
      score += 0.86;
    } else if (coverage >= 0.67 && strongHits >= 2) {
      score += 0.50;
    } else if (strongHits == 1 &&
        bestSingleTokenWord.length >= 7 &&
        bestSingleToken >= 0.86 &&
        !_isAmbiguousToken(bestSingleTokenWord) &&
        lineWords.length >= 2) {
      // Caso OCR típico: nombre partido o deformado, pero apellido largo y único bien leído.
      // Ejemplo: "JO KO GUARDIOL" debe acercarse a JOŠKO GVARDIOL.
      score += 0.86;
    } else if (strongHits == 1 &&
        bestSingleTokenWord.length >= 6 &&
        bestSingleToken >= 0.9) {
      score += 0.30;
    } else if (strongHits == 1) {
      score += 0.10;
    } else {
      return 0;
    }

    final teamHint = teamHints[player.teamId.toUpperCase()];
    if (teamHint != null) {
      if (teamHint.exact) {
        score += 0.20;
      } else if (teamHint.fuzzy) {
        score += 0.10;
      }
    }

    if (strongHits == 1 && _isAmbiguousToken(bestSingleTokenWord)) {
      score -= 0.25;
    }

    if (lineWords.length <= 2 && strongHits == 1) {
      score -= 0.20;
    }

    return score.clamp(0.0, 1.0);
  }

  void _ensureTokenFrequencyAcrossPlayers() {
    if (_tokenFrequencyAcrossPlayers != null) return;
    final freq = <String, int>{};
    for (final p in _allPlayerStickers()) {
      final name = WorldCup2026Seed.normalizeTextForPlayerNameMatch(
        p.playerName ?? '',
      );
      final tokens = name
          .split(' ')
          .where((w) => w.length >= 4 && !_noiseTokens.contains(w))
          .toSet();
      for (final t in tokens) {
        freq.update(t, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    _tokenFrequencyAcrossPlayers = freq;
  }

  bool _isAmbiguousToken(String token) {
    if (token.isEmpty) return true;
    final n = _tokenFrequencyAcrossPlayers?[token] ?? 0;
    return n > 1;
  }

  double _normalizedSimilarity(String a, String b) {
    final aa = _normalizeTokenForOcrConfusions(a);
    final bb = _normalizeTokenForOcrConfusions(b);
    if (aa.isEmpty || bb.isEmpty) return 0;
    if (aa == bb) return 1;
    final d = _levenshteinDistance(aa, bb);
    final maxLen = aa.length > bb.length ? aa.length : bb.length;
    if (maxLen == 0) return 0;
    final v = 1.0 - (d / maxLen);
    if (v < 0) return 0;
    if (v > 1) return 1;
    return v;
  }

  String _normalizeTokenForOcrConfusions(String input) {
    return input
        .toLowerCase()
        // OCR frecuente en fotos: U y V se confunden fácilmente.
        .replaceAll('u', 'v')
        // En tomas inclinadas también aparece Y↔V (YERRY -> VERRY).
        .replaceAll('y', 'v')
        // En algunos OCR, l mayúscula y i también se mezclan.
        .replaceAll('l', 'i');
  }

  int _levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final m = a.length;
    final n = b.length;
    final prev = List<int>.generate(n + 1, (j) => j);
    final curr = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= m; i++) {
      curr[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final deletion = prev[j] + 1;
        final insertion = curr[j - 1] + 1;
        final substitution = prev[j - 1] + cost;
        var best = deletion < insertion ? deletion : insertion;
        if (substitution < best) best = substitution;
        curr[j] = best;
      }
      for (var j = 0; j <= n; j++) {
        prev[j] = curr[j];
      }
    }
    return prev[n];
  }
}

class _ScoredCandidate {
  const _ScoredCandidate({required this.player, required this.score});
  final StickerModel player;
  final double score;
}

class _TeamHint {
  const _TeamHint({required this.exact, required this.fuzzy});
  final bool exact;
  final bool fuzzy;
}
