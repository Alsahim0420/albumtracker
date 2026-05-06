import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/features/home/domain/services/ocr/player_name_ocr_fuzzy_match.dart';
import 'package:albumtracker/features/home/domain/services/sticker_matcher_service.dart';

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

  /// Solo debug: rechazos de monónimos cortos (Rodri vs RODR de Rodríguez).
  final List<String> _shortAliasRejectLog = <String>[];

  /// Evita repetir el mismo motivo de equipo por jugador en un mismo [matchAll].
  final Set<String> _shortAliasTeamRejectLoggedIds = <String>{};

  /// Todas las láminas detectables en el texto (puede repetir el mismo id si varias
  /// líneas OCR matchean la misma lámina, p. ej. dos ejemplares en una foto).
  ///
  /// Si el OCR incluye varios jugadores del **mismo** equipo pero **no** lee el código
  /// código de equipo (NED, ARG…), se confía en el consenso de nombres y no se exige `NED` en texto.
  ///
  /// Además, si hay consenso de equipo, se intentan coincidencias por **fragmentos**
  /// únicos del nombre (p. ej. `meiners` → Teun Koopmeiners, `ligt` → Matthijs de Ligt)
  /// cuando el OCR parte o tuerce el nombre completo.
  ///
  /// [requireExplicitFullPlayerNameInBlob]: en collages con reverso FIFA en el mismo OCR,
  /// solo se aceptan jugadores con nombre claramente legible (evita país de club + consenso).
  List<StickerModel> matchAllWithCountryInText(
    String rawOcrText, {
    bool requireExplicitFullPlayerNameInBlob = false,
  }) {
    final scrubbed = StickerMatcherService.stripClubNationHintsForOcr(rawOcrText);
    final normalizedBlob = WorldCup2026Seed.normalizeTextForPlayerNameMatch(
      scrubbed,
    );
    if (normalizedBlob.isEmpty) return [];

    _shortAliasRejectLog.clear();
    _shortAliasTeamRejectLoggedIds.clear();

    _ensureTokenFrequencyAcrossPlayers();
    final teamHints = _buildTeamHints(scrubbed);
    final players = _allPlayerStickers();
    final lines = _extractCandidateLines(scrubbed);
    final ordered = <StickerModel>[];

    // Salida final = [ordered] (ocurrencias físicas, orden de lectura). Los Maps/Sets
    // solo sirven para expansión interna, nunca para colapsar la lista final.

    // 1) Strict: solo pistas (jugadores presentes en el blob); puede ser < ocurrencias.
    final strict = PlayerNameOcrFuzzy.findPlayerStickersForOcrBlob(
      scrubbed,
      onNameFuzzyReject: StickerMatcherService.logRejectedMatch,
    );

    final multiLineScan = lines.length >= 6;
    final lineThreshold = multiLineScan ? 0.82 : _autoAddThreshold;
    final lineDeltaMin = multiLineScan ? 0.08 : _topDeltaThreshold;

    // 2) Una entrada en [ordered] por línea con match claro (mismo id puede repetirse).
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
      final wellSeparated = delta >= lineDeltaMin;
      final highConfidence = top.score >= 0.905;
      if (top.score >= lineThreshold && (wellSeparated || highConfidence)) {
        ordered.add(top.player);
      }
    }

    // 3) Consenso: ids ya vistos al menos una vez (no bloquea repetir en paso 2; solo
    // evita meter el mismo jugador otra vez desde *esta* expansión si ya hay una fila).
    var foundIds = ordered.map((s) => s.id).toSet();
    final idsPerTeam = <String, Set<String>>{};
    for (final s in ordered) {
      idsPerTeam.putIfAbsent(s.teamId, () => {}).add(s.id);
    }
    final consensusTeams = idsPerTeam.entries
        .where((e) => e.value.length >= 2)
        .map((e) => e.key)
        .toSet();
    if (!requireExplicitFullPlayerNameInBlob && consensusTeams.isNotEmpty) {
      for (final line in lines) {
        for (final player in players.where(
          (p) => consensusTeams.contains(p.teamId) && !foundIds.contains(p.id),
        )) {
          final score = _scorePlayerLineMatch(
            line: line,
            player: player,
            teamHints: teamHints,
          );
          if (score >= (lineThreshold - 0.05)) {
            ordered.add(player);
            foundIds.add(player.id);
          }
        }
      }
    }

    // 4) Fallback collage por apellido en el blob.
    foundIds = ordered.map((s) => s.id).toSet();
    if (!requireExplicitFullPlayerNameInBlob && foundIds.length >= 4) {
      final blobWords = normalizedBlob
          .split(' ')
          .where((w) => w.length >= 4)
          .toSet()
          .toList(growable: false);
      for (final player in players.where((p) => !foundIds.contains(p.id))) {
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
        if (!PlayerNameOcrFuzzy.sharedSurnameBlobHasExactGivenNames(
          player,
          normalizedBlob,
        )) {
          continue;
        }

        ordered.add(player);
        foundIds.add(player.id);
      }
    }

    for (final s in strict) {
      if (!ordered.any((x) => x.id == s.id)) {
        ordered.add(s);
      }
    }

    final wordList = normalizedBlob
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList(growable: false);

    List<StickerModel>? greedyResult;
    var greedyExactIdsRun = const <String>[];
    var greedyFuzzyAcceptedIdsRun = const <String>[];
    if (wordList.length >= 8 &&
        !requireExplicitFullPlayerNameInBlob &&
        players.isNotEmpty) {
      final greedyPool = _greedyCandidatePlayers(strict, players, teamHints);
      if (greedyPool.isNotEmpty) {
        final greedyMinScore =
            (multiLineScan || wordList.length >= 12) ? 0.82 : _autoAddThreshold;
        final greedyPack = _greedyPlayerSpansFromWords(
          wordList,
          greedyPool,
          teamHints,
          minScore: greedyMinScore,
        );
        greedyResult = greedyPack.stickers;
        greedyExactIdsRun = greedyPack.greedyExactIds;
        greedyFuzzyAcceptedIdsRun = greedyPack.fuzzyAcceptedIds;
      }
    }

    if (greedyResult != null && greedyResult.length > ordered.length) {
      ordered
        ..clear()
        ..addAll(greedyResult);
    }

    if (requireExplicitFullPlayerNameInBlob) {
      ordered.removeWhere(
        (s) => !StickerMatcherService.playerHasExplicitNameEvidence(s, scrubbed),
      );
    }

    var out = List<StickerModel>.from(ordered);

    if (greedyResult != null && greedyExactIdsRun.isNotEmpty) {
      final allowed = <String>{
        for (final s in greedyResult) s.id,
        ...greedyExactIdsRun,
        ...greedyFuzzyAcceptedIdsRun,
      };
      final dominant = _dominantTeamIdFromStickers(greedyResult);
      if (dominant != null) {
        final shortMonoRejected = _stickerIdsRejectedShortMonoThisRun();
        for (final s in strict) {
          if (s.teamId.toUpperCase() != dominant) continue;
          if (shortMonoRejected.contains(s.id)) continue;
          allowed.add(s.id);
        }
      }
      final filteredOut = out.where((s) => !allowed.contains(s.id)).map((s) => s.id).toSet();
      if (filteredOut.isNotEmpty) {
        out = out.where((s) => allowed.contains(s.id)).toList();
      }
    }

    return out;
  }

  /// Fallback de alta tolerancia para OCR sucio de una sola lámina frontal.
  /// Retorna un único jugador cuando el top es claramente mejor que el segundo.
  StickerModel? matchSingleBestEffort(
    String rawOcrText, {
    bool requireExplicitFullPlayerNameInBlob = false,
  }) {
    final scrubbed = StickerMatcherService.stripClubNationHintsForOcr(rawOcrText);
    final players = _allPlayerStickers();
    final lines = _extractCandidateLines(scrubbed);
    if (lines.isEmpty) return null;
    final teamHints = _buildTeamHints(scrubbed);
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
      if (requireExplicitFullPlayerNameInBlob &&
          !StickerMatcherService.playerHasExplicitNameEvidence(top.player, scrubbed)) {
        return null;
      }
      return top.player;
    }
    return null;
  }

  /// Plantel (o todo el seed) con el que probar spans en modo greedy.
  List<StickerModel> _greedyCandidatePlayers(
    List<StickerModel> strict,
    List<StickerModel> allPlayers,
    Map<String, _TeamHint> teamHints,
  ) {
    final exactTeams = teamHints.entries
        .where((e) => e.value.exact)
        .map((e) => e.key.toUpperCase())
        .toList(growable: false);
    if (exactTeams.length == 1) {
      final tid = exactTeams[0];
      return allPlayers
          .where((p) => p.teamId.toUpperCase() == tid)
          .toList(growable: false);
    }
    if (strict.isNotEmpty) {
      final tids = strict.map((p) => p.teamId.toUpperCase()).toSet();
      if (tids.length == 1) {
        final tid = tids.first;
        return allPlayers
            .where((p) => p.teamId.toUpperCase() == tid)
            .toList(growable: false);
      }
    }
    return allPlayers;
  }

  /// Recorre [words] izquierda → derecha; cada span aceptado añade **una** fila
  /// (el mismo [StickerModel.id] puede repetirse). [spanCandidates] suele ser el
  /// plantel del equipo inferido, no solo ids únicos del strict.
  ///
  /// Prioridad: secuencia **exacta** palabra a palabra del nombre normalizado (p. ej.
  /// `lyle foster` → RSA-17) antes que spans fuzzy, para no “robar” tokens entre
  /// jugadores ni inflar un mismo apellido en el blob.
  ///
  /// El índice [i] avanza de uno en uno; las palabras cubiertas por un span aceptado
  /// se marcan en [consumed] para no reutilizarlas, sin saltar al final del span
  /// (evita perder coincidencias que empiezan en tokens intermedios).
  /// [greedyExactIds]: spans exactos; [fuzzyAcceptedIds]: spans fuzzy del mismo barrido.
  ({
    List<StickerModel> stickers,
    List<String> greedyExactIds,
    List<String> fuzzyAcceptedIds,
  }) _greedyPlayerSpansFromWords(
    List<String> words,
    List<StickerModel> spanCandidates,
    Map<String, _TeamHint> teamHints, {
    double minScore = _autoAddThreshold,
  }) {
    if (spanCandidates.isEmpty) {
      return (
        stickers: <StickerModel>[],
        greedyExactIds: <String>[],
        fuzzyAcceptedIds: <String>[],
      );
    }

    final out = <StickerModel>[];
    final greedyExactIds = <String>[];
    final fuzzyAcceptedIds = <String>[];
    final consumed = List<bool>.filled(words.length, false);
    var i = 0;
    while (i < words.length) {
      if (consumed[i]) {
        i++;
        continue;
      }

      final exact = _tryExactFullNameWordSpanAt(words, i, spanCandidates, consumed);
      if (exact != null) {
        out.add(exact.player);
        greedyExactIds.add(exact.player.id);
        _markSpanConsumed(consumed, i, exact.end);
        i++;
        continue;
      }

      final matches = <({StickerModel p, int end, double score, int spanLen, int hasFullName})>[];
      for (final player in spanCandidates) {
        final playerName = WorldCup2026Seed.normalizeTextForPlayerNameMatch(
          player.playerName ?? '',
        );
        final rawNameWords = playerName
            .split(' ')
            .where((w) => w.length >= 2 && !_noiseTokens.contains(w))
            .toList(growable: false);
        if (rawNameWords.isEmpty) continue;
        final minSpan = rawNameWords.length >= 2 ? 2 : 1;
        // +1 en lugar de +2: evita que un fuzzy absorba la primera palabra del siguiente.
        final maxSpan = (rawNameWords.length + 1).clamp(minSpan, 6);
        for (var len = minSpan; len <= maxSpan && i + len <= words.length; len++) {
          if (!_spanRangeUnconsumed(consumed, i, i + len)) continue;
          final spanText = words.sublist(i, i + len).join(' ');
          final score = _scorePlayerLineMatch(
            line: spanText,
            player: player,
            teamHints: teamHints,
          );
          if (score >= minScore) {
            final hasFull = playerName.length >= 4 && spanText.contains(playerName) ? 1 : 0;
            matches.add((
              p: player,
              end: i + len,
              score: score,
              spanLen: len,
              hasFullName: hasFull,
            ));
          }
        }
      }
      if (matches.isEmpty) {
        i++;
        continue;
      }
      matches.sort((a, b) {
        final c = b.hasFullName.compareTo(a.hasFullName);
        if (c != 0) return c;
        final c2 = b.score.compareTo(a.score);
        if (c2 != 0) return c2;
        return a.spanLen.compareTo(b.spanLen);
      });
      final top = matches.first;
      final spanText = words.sublist(i, top.end).join(' ');
      if (!_fuzzySpanPassesAnchorGate(spanText, top.p, top.score)) {
        i++;
        continue;
      }
      double? secondScore;
      for (final m in matches.skip(1)) {
        if (m.p.id != top.p.id) {
          secondScore = m.score;
          break;
        }
      }
      final delta = secondScore == null ? 1.0 : top.score - secondScore;
      final greedyDeltaMin = 0.08;
      final typoTwoTokenOk = _fuzzySpanRelaxesAmbiguousDelta(spanText, top.p);
      if (delta < greedyDeltaMin && top.score < 0.905 && !typoTwoTokenOk) {
        i++;
        continue;
      }
      out.add(top.p);
      fuzzyAcceptedIds.add(top.p.id);
      _markSpanConsumed(consumed, i, top.end);
      i++;
    }

    return (
      stickers: out,
      greedyExactIds: greedyExactIds,
      fuzzyAcceptedIds: List<String>.from(fuzzyAcceptedIds),
    );
  }

  /// Equipo más frecuente en la salida greedy (p. ej. todo MEX en una foto).
  String? _dominantTeamIdFromStickers(List<StickerModel> stickers) {
    if (stickers.isEmpty) return null;
    final counts = <String, int>{};
    for (final s in stickers) {
      final t = s.teamId.toUpperCase();
      counts[t] = (counts[t] ?? 0) + 1;
    }
    var best = '';
    var bestN = 0;
    counts.forEach((k, v) {
      if (v > bestN) {
        bestN = v;
        best = k;
      }
    });
    return best.isEmpty ? null : best;
  }

  /// Ids con rechazo monónimo corto en esta corrida (no reinyectar desde strict).
  Set<String> _stickerIdsRejectedShortMonoThisRun() {
    final out = <String>{};
    for (final e in _shortAliasRejectLog) {
      final pipe = e.indexOf('|');
      if (pipe <= 0) continue;
      final reason = e.substring(pipe + 1);
      if (reason.startsWith('shortMono:')) {
        out.add(e.substring(0, pipe));
      }
    }
    return out;
  }

  bool _spanRangeUnconsumed(List<bool> consumed, int start, int endExclusive) {
    for (var k = start; k < endExclusive; k++) {
      if (consumed[k]) return false;
    }
    return true;
  }

  void _markSpanConsumed(List<bool> consumed, int start, int endExclusive) {
    for (var k = start; k < endExclusive; k++) {
      consumed[k] = true;
    }
  }

  /// Coincidencia exacta token a token del nombre normalizado (≥2 tokens significativos).
  ({StickerModel player, int end})? _tryExactFullNameWordSpanAt(
    List<String> words,
    int i,
    List<StickerModel> spanCandidates,
    List<bool> consumed,
  ) {
    if (i >= words.length) return null;
    ({StickerModel player, int end, int nameLen})? best;
    for (final player in spanCandidates) {
      if (player.type != StickerType.player) continue;
      final playerName = WorldCup2026Seed.normalizeTextForPlayerNameMatch(
        player.playerName ?? '',
      );
      final nameTokens = playerName
          .split(' ')
          .where((w) => w.length >= 2 && !_noiseTokens.contains(w))
          .toList(growable: false);
      if (nameTokens.length < 2) continue;
      if (i + nameTokens.length > words.length) continue;
      if (!_spanRangeUnconsumed(consumed, i, i + nameTokens.length)) continue;
      var allEq = true;
      for (var k = 0; k < nameTokens.length; k++) {
        if (words[i + k] != nameTokens[k]) {
          allEq = false;
          break;
        }
      }
      if (!allEq) continue;
      final end = i + nameTokens.length;
      final cand = (player: player, end: end, nameLen: nameTokens.length);
      if (best == null || cand.nameLen > best.nameLen) {
        best = cand;
      } else if (cand.nameLen == best.nameLen) {
        if (cand.player.id.compareTo(best.player.id) < 0) best = cand;
      }
    }
    if (best == null) return null;
    return (player: best.player, end: best.end);
  }

  /// Evita fuzzy débil con un solo apellido/token compartido en spans cortos.
  /// Alineado con [_scorePlayerLineMatch]: acepta 1 token ≥0.88 + otro ≥0.78 (OCR 1 letra).
  bool _fuzzySpanPassesAnchorGate(String spanText, StickerModel player, double score) {
    if (score >= 0.93) return true;
    final pn = WorldCup2026Seed.normalizeTextForPlayerNameMatch(
      player.playerName ?? '',
    );
    final nameWords = pn
        .split(' ')
        .where((w) => w.length >= 2 && !_noiseTokens.contains(w))
        .toList(growable: false);
    if (nameWords.length < 2) return true;
    final sn = WorldCup2026Seed.normalizeTextForPlayerNameMatch(spanText);
    if (pn.length >= 4 && sn.contains(pn)) return true;
    if (_normalizedSimilarity(pn, sn) >= 0.94) return true;
    if (_countStrongNameWordHits(spanText, player, threshold: 0.88) >= 2) return true;
    if (_fuzzySpanHasStrongPlusMediumToken(spanText, player)) return true;
    return score >= 0.82 && _countStrongNameWordHits(spanText, player, threshold: 0.76) >= 2;
  }

  /// Misma idea que strongHits+mediumHits en [_scorePlayerLineMatch] (p. ej. SVBONGA + NGEZANA).
  bool _fuzzySpanHasStrongPlusMediumToken(String spanText, StickerModel player) {
    final pn = WorldCup2026Seed.normalizeTextForPlayerNameMatch(
      player.playerName ?? '',
    );
    final nameWords = pn
        .split(' ')
        .where((w) => w.length >= 2 && !_noiseTokens.contains(w))
        .toList(growable: false);
    if (nameWords.length < 2) return false;
    final lineWords = spanText.split(' ').where((w) => w.isNotEmpty).toList();
    var strong = 0;
    var medium = 0;
    for (final nw in nameWords) {
      var best = 0.0;
      for (final lw in lineWords) {
        final s = _normalizedSimilarity(nw, lw);
        if (s > best) best = s;
      }
      if (best >= 0.88) {
        strong++;
      } else if (best >= 0.78 && nw.length >= 4) {
        medium++;
      }
    }
    return strong >= 1 && medium >= 1;
  }

  /// Permite aceptar top aunque el segundo candidato esté muy cerca (OCR ruidoso).
  bool _fuzzySpanRelaxesAmbiguousDelta(String spanText, StickerModel player) {
    final pn = WorldCup2026Seed.normalizeTextForPlayerNameMatch(
      player.playerName ?? '',
    );
    final nameWords = pn
        .split(' ')
        .where((w) => w.length >= 2 && !_noiseTokens.contains(w))
        .toList(growable: false);
    if (nameWords.length < 2) return false;
    final lineWords = spanText.split(' ').where((w) => w.isNotEmpty).toList();
    var strong = 0;
    var medium = 0;
    for (final nw in nameWords) {
      var best = 0.0;
      for (final lw in lineWords) {
        final s = _normalizedSimilarity(nw, lw);
        if (s > best) best = s;
      }
      if (best >= 0.88) {
        strong++;
      } else if (best >= 0.78 && nw.length >= 4) {
        medium++;
      }
    }
    return (strong >= 1 && medium >= 1) || strong >= 2;
  }

  int _countStrongNameWordHits(
    String spanText,
    StickerModel player, {
    required double threshold,
  }) {
    final pn = WorldCup2026Seed.normalizeTextForPlayerNameMatch(
      player.playerName ?? '',
    );
    final nameWords = pn
        .split(' ')
        .where((w) => w.length >= 2 && !_noiseTokens.contains(w))
        .toList(growable: false);
    if (nameWords.isEmpty) return 0;
    final lineWords = spanText.split(' ').where((w) => w.isNotEmpty).toList();
    var hits = 0;
    for (final nw in nameWords) {
      var best = 0.0;
      for (final lw in lineWords) {
        final s = _normalizedSimilarity(nw, lw);
        if (s > best) best = s;
      }
      if (best >= threshold) hits++;
    }
    return hits;
  }

  /// Líneas candidatas en orden. **No** deduplica: la misma línea normalizada
  /// puede repetirse (foto con varias copias del mismo jugador, una por carta).
  List<String> _extractCandidateLines(String rawOcrText) {
    final out = <String>[];
    for (final line in rawOcrText.split('\n')) {
      final normalized = WorldCup2026Seed.normalizeTextForPlayerNameMatch(line);
      if (normalized.length < 5) continue;
      out.add(normalized);
    }
    return out;
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

  Map<String, _TeamHint> _buildTeamHints(String rawOcrTextUpperStripped) {
    final upper = rawOcrTextUpperStripped.toUpperCase();
    final out = <String, _TeamHint>{};

    for (final g in WorldCup2026Seed.groups) {
      for (final t in g.teams) {
        final tid = t.id.toUpperCase();
        if (tid.length != 3) continue;
        // Solo palabra completa; nada de fuzzy por tokens (evita GER por ruido/club).
        final exact = RegExp(r'\b' + RegExp.escape(tid) + r'\b').hasMatch(upper);
        if (exact) {
          out[tid] = const _TeamHint(exact: true, fuzzy: false);
        }
      }
    }
    return out;
  }

  /// Monónimo corto tipo Rodri / Pedri / Gavi: no fuzzy débil contra apellidos largos.
  bool _isShortMonolexicAlias(List<String> nameWords) {
    if (nameWords.length != 1) return false;
    final a = nameWords.first;
    return a.length >= 2 && a.length <= 6;
  }

  void _logShortAliasReject(StickerModel player, String reason) {
    _shortAliasRejectLog.add('${player.id}|$reason');
  }

  /// Fragmentos OCR típicos de RODRIGUEZ / RODRIGO… que no deben acercarse a "Rodri".
  bool _tokenIsLikelyRodriguezFamilyFragment(String lw, String alias) {
    if (alias.toUpperCase() != 'RODRI') return false;
    final u = lw.toUpperCase();
    if (u == 'RODR') return true;
    if (u.startsWith('RODRIG')) return true;
    if (u.startsWith('RODR') && u.length >= 6) return true;
    return false;
  }

  /// Solo palabra completa igual al alias, o fuzzy muy alto con longitud casi igual.
  double _scoreShortMonolexicAliasLine({
    required List<String> lineWords,
    required StickerModel player,
    required String alias,
    required Map<String, _TeamHint> teamHints,
  }) {
    final tid = player.teamId.toUpperCase();
    if (teamHints.isNotEmpty && !teamHints.containsKey(tid)) {
      if (_shortAliasTeamRejectLoggedIds.add(player.id)) {
        _logShortAliasReject(
          player,
          'shortMono:noTeamEvidence need=$tid have=${teamHints.keys.join(",")}',
        );
      }
      return 0;
    }

    if (lineWords.contains(alias)) {
      var score = 0.75;
      final teamHint = teamHints[tid];
      if (teamHint != null) {
        if (teamHint.exact) {
          score += 0.20;
        } else if (teamHint.fuzzy) {
          score += 0.10;
        }
      }
      return score.clamp(0.0, 1.0);
    }

    double best = 0.0;
    String? bestTok;
    for (final lw in lineWords) {
      if (_tokenIsLikelyRodriguezFamilyFragment(lw, alias)) continue;
      final s = _normalizedSimilarity(alias, lw);
      if (s > best) {
        best = s;
        bestTok = lw;
      }
    }

    const minFuzzy = 0.96;
    if (bestTok == null || best < minFuzzy) {
      if (best >= 0.72) {
        _logShortAliasReject(
          player,
          'shortMono:fuzzyRejected sim=${best.toStringAsFixed(3)} tok=${bestTok ?? "?"}',
        );
      }
      return 0;
    }

    final lenDiff = (alias.length - bestTok.length).abs();
    if (lenDiff > 1) {
      if (best >= 0.72) {
        _logShortAliasReject(
          player,
          'shortMono:lenDiffRejected diff=$lenDiff tok=$bestTok sim=${best.toStringAsFixed(3)}',
        );
      }
      return 0;
    }

    var score = 0.75;
    final teamHint = teamHints[tid];
    if (teamHint != null) {
      if (teamHint.exact) {
        score += 0.20;
      } else if (teamHint.fuzzy) {
        score += 0.10;
      }
    }
    return score.clamp(0.0, 1.0);
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

    if (_isShortMonolexicAlias(nameWords)) {
      return _scoreShortMonolexicAliasLine(
        lineWords: lineWords,
        player: player,
        alias: nameWords.first,
        teamHints: teamHints,
      );
    }

    final strongTok = PlayerNameOcrFuzzy.strongTokensNormalized(playerName);
    final lineWordSet = lineWords.toSet();
    final fullSim = _normalizedSimilarity(playerName, line);
    final hasFullNameEvidence = line.contains(playerName) || fullSim >= 0.95;
    if (!hasFullNameEvidence &&
        strongTok.length >= 2 &&
        PlayerNameOcrFuzzy.isSharedLastStrongSurnameToken(strongTok.last)) {
      final given = strongTok
          .sublist(0, strongTok.length - 1)
          .where((g) => g.length >= 3)
          .toList(growable: false);
      if (given.isEmpty) return 0;
      if (!given.every(lineWordSet.contains)) return 0;
    }

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
    final aa = PlayerNameOcrFuzzy.foldForPaniniOcrCompare(a);
    final bb = PlayerNameOcrFuzzy.foldForPaniniOcrCompare(b);
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
