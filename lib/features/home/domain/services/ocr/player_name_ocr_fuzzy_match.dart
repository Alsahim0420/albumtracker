import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/models/sticker_model.dart';

/// Fuzzy **solo** para nombres de jugador en OCR tipo Panini/FIFA 2026.
/// No toca códigos de país, lámina, club ni reversos FIFA.
class PlayerNameOcrFuzzy {
  PlayerNameOcrFuzzy._();

  static Set<String>? _sharedLastStrongSurnames;

  /// Apellido “fuerte” final compartido por ≥2 jugadores en el seed (p. ej. pašalić).
  static void _ensureSharedLastStrongSurnames() {
    if (_sharedLastStrongSurnames != null) return;
    final counts = <String, int>{};
    for (final g in WorldCup2026Seed.groups) {
      for (final t in g.teams) {
        for (final sticker in t.stickers) {
          if (sticker.type != StickerType.player) continue;
          final key = WorldCup2026Seed.normalizeTextForPlayerNameMatch(
            sticker.playerName ?? '',
          );
          final strong = _strongTokens(key);
          if (strong.isEmpty) continue;
          final last = strong.last;
          if (last.length < 3) continue;
          counts[last] = (counts[last] ?? 0) + 1;
        }
      }
    }
    _sharedLastStrongSurnames = {
      for (final e in counts.entries)
        if (e.value >= 2) e.key,
    };
  }

  static bool isSharedLastStrongSurnameToken(String normalizedLastStrongSurname) {
    _ensureSharedLastStrongSurnames();
    return _sharedLastStrongSurnames!.contains(normalizedLastStrongSurname);
  }

  /// Tokens fuertes ya [WorldCup2026Seed.normalizeTextForPlayerNameMatch].
  static List<String> strongTokensNormalized(String normalizedPlayerName) =>
      _strongTokens(normalizedPlayerName);

  /// Si el apellido final es compartido, cada nombre de pila fuerte debe aparecer
  /// como palabra exacta en [normalizedBlob] (misma normalización que el OCR).
  static bool sharedSurnameBlobHasExactGivenNames(
    StickerModel player,
    String normalizedBlob,
  ) {
    if (player.type != StickerType.player) return true;
    final key = WorldCup2026Seed.normalizeTextForPlayerNameMatch(
      player.playerName ?? '',
    );
    final strong = _strongTokens(key);
    if (strong.length < 2) return true;
    final last = strong.last;
    if (!isSharedLastStrongSurnameToken(last)) return true;
    final given = strong
        .sublist(0, strong.length - 1)
        .where((t) => t.length >= 3)
        .toList();
    if (given.isEmpty) return false;
    final words = normalizedBlob.split(' ').where((w) => w.isNotEmpty).toSet();
    return given.every(words.contains);
  }

  /// Conectores / partículas que no bastan solos para matchear.
  static const Set<String> _weakTokens = {
    'el', 'de', 'da', 'dos', 'van', 'al', 'del', 'la', 'le', 'il', 'et', 'und',
    'di', 'bin', 'zu', 'zur', 'vom', 'im', 'am', 'en', 'un', 'una', 'y', 'e',
    'jr', 'sr', 'ii', 'iii', 'iv',
  };

  /// Coincidencia exacta (substring) + fuzzy conservador por tokens.
  static List<StickerModel> findPlayerStickersForOcrBlob(
    String rawOcrText, {
    void Function(String stickerId, String reason)? onNameFuzzyReject,
  }) {
    final exact = WorldCup2026Seed.findStickersByPlayerNamesInText(rawOcrText);
    final blob = WorldCup2026Seed.normalizeTextForPlayerNameMatch(rawOcrText);
    if (blob.length < 4) return exact;

    final byId = <String, StickerModel>{for (final s in exact) s.id: s};

    for (final g in WorldCup2026Seed.groups) {
      for (final t in g.teams) {
        for (final sticker in t.stickers) {
          if (sticker.type != StickerType.player) continue;
          if (byId.containsKey(sticker.id)) continue;
          final key = WorldCup2026Seed.normalizeTextForPlayerNameMatch(
            sticker.playerName ?? '',
          );
          if (key.length < 4 || blob.contains(key)) continue;
          final match = _evaluateFuzzyMatch(
            sticker,
            blob,
            onReject: onNameFuzzyReject,
          );
          if (match != null) {
            byId[sticker.id] = sticker;
          }
        }
      }
    }
    return byId.values.toList(growable: false);
  }

  static bool playerNameMatchesBlobEvidence(StickerModel player, String normalizedBlob) {
    if (player.type != StickerType.player) return true;
    if (WorldCup2026Seed.normalizeTextForPlayerNameMatch(player.playerName ?? '').length <
        6) {
      return false;
    }
    return _evaluateFuzzyMatch(
          player,
          normalizedBlob,
          onReject: null,
        ) !=
        null;
  }

  static _FuzzyMatchDetail? _evaluateFuzzyMatch(
    StickerModel sticker,
    String blob, {
    void Function(String stickerId, String reason)? onReject,
  }) {
    final playerNorm =
        WorldCup2026Seed.normalizeTextForPlayerNameMatch(sticker.playerName ?? '');
    // Monónimos (Rodri, Gavi, Pedri): sin fuzzy; solo vale el exact match del caller.
    if (_meaningfulWordCount(playerNorm) < 2) {
      onReject?.call(
        sticker.id,
        'singleWordPlayerName:noFuzzy',
      );
      return null;
    }

    final strong = _strongTokens(playerNorm);
    if (strong.isEmpty) return null;

    // Nombre multi-palabra pero un solo token "fuerte" (p. ej. partícula débil + apellido).
    if (strong.length == 1) {
      final t = strong.first;
      if (isSharedLastStrongSurnameToken(t)) {
        return null;
      }
      final best = _bestTokenVsCandidates(t, _ocrCandidates(blob));
      if (best.score >= 0.92) {
        final detail = _FuzzyMatchDetail(
          rawOcrToken: best.raw,
          seedToken: t,
          similarityScore: best.score,
          reason: 'single_strong_token_multivoice_name_fuzzy',
        );
        return detail;
      }
      return null;
    }

    final primary = strong.last;
    final others = strong.sublist(0, strong.length - 1);
    final cands = _ocrCandidates(blob);
    final blobWords = blob.split(' ').where((w) => w.isNotEmpty).toSet();
    final surnameShared = isSharedLastStrongSurnameToken(primary);

    final primaryBest = _bestTokenVsCandidates(primary, cands);
    if (primaryBest.score < 0.84) return null;

    var secondaryOk = false;
    _ScoreTriplet? secondaryBest;
    if (surnameShared) {
      final givenNeedExact =
          others.where((o) => o.length >= 3).toList(growable: false);
      if (givenNeedExact.isEmpty) {
        return null;
      }
      for (final o in givenNeedExact) {
        if (blobWords.contains(o)) {
          secondaryOk = true;
          secondaryBest ??= _ScoreTriplet(o, 1.0);
          continue;
        }
        final b = _bestTokenVsCandidates(o, cands);
        if (b.score >= 0.76) {
          onReject?.call(
            sticker.id,
            'shared surname "$primary" requires exact first-name match; '
            'OCR first name "${b.raw}" != seed first name "$o"',
          );
        }
        return null;
      }
    } else {
      for (final o in others) {
        if (o.length < 3) continue;
        final b = _bestTokenVsCandidates(o, cands);
        if (b.score >= 0.76) {
          secondaryOk = true;
          if (secondaryBest == null || b.score > secondaryBest.score) {
            secondaryBest = b;
          }
        }
      }
      if (!secondaryOk) return null;
    }

    final detail = _FuzzyMatchDetail(
      rawOcrToken: '${primaryBest.raw}|${secondaryBest?.raw ?? ''}',
      seedToken: '$primary+${others.join(",")}',
      similarityScore: (primaryBest.score + (secondaryBest?.score ?? 0)) / 2,
      reason: 'dual_strong_token_fuzzy',
    );
    return detail;
  }

  static int _meaningfulWordCount(String normalizedPlayerName) {
    return normalizedPlayerName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .length;
  }

  /// Tokens “fuertes” del nombre (sin conectores); el último suele ser apellido.
  static List<String> _strongTokens(String normalizedPlayerName) {
    final parts = normalizedPlayerName
        .split(' ')
        .where((w) => w.isNotEmpty && !_weakTokens.contains(w))
        .toList();
    return parts.where((w) => w.length >= 3).toList();
  }

  static List<String> _ocrCandidates(String blob) {
    final t = blob.split(' ').where((w) => w.isNotEmpty).toList();
    final out = <String>{};
    for (var i = 0; i < t.length; i++) {
      out.add(t[i]);
      if (i + 1 < t.length) {
        out.add(t[i] + t[i + 1]);
      }
      if (i + 2 < t.length) {
        out.add(t[i] + t[i + 1] + t[i + 2]);
      }
    }
    return out.where((s) => s.length >= 3).toList(growable: false);
  }

  static _ScoreTriplet _bestTokenVsCandidates(String seedToken, List<String> candidates) {
    var bestScore = 0.0;
    var bestRaw = '';
    final fs = foldForPaniniOcrCompare(seedToken);
    for (final c in candidates) {
      final fc = foldForPaniniOcrCompare(c);
      if (fc.isEmpty) continue;
      final d = _levenshtein(fs, fc);
      final m = fs.length > fc.length ? fs.length : fc.length;
      final sim = m == 0 ? 0.0 : 1.0 - (d / m);
      if (sim > bestScore) {
        bestScore = sim;
        bestRaw = c;
      }
    }
    return _ScoreTriplet(bestRaw, bestScore);
  }

  /// Plegado OCR Panini/FIFA solo para comparar **tokens de nombre**.
  static String foldForPaniniOcrCompare(String token) {
    var s = token.toLowerCase();
    const accents = <String, String>{
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'ñ': 'n', 'ç': 'c', 'ý': 'y', 'ÿ': 'y',
      'ć': 'c', 'č': 'c', 'š': 's', 'ž': 'z', 'đ': 'd',
      'ł': 'l', 'ń': 'n', 'ś': 's', 'ź': 'z', 'ż': 'z',
    };
    for (final e in accents.entries) {
      s = s.replaceAll(e.key, e.value);
    }
    final buf = StringBuffer();
    for (final ch in s.runes) {
      final c = String.fromCharCode(ch);
      if (RegExp(r'[a-z]').hasMatch(c)) {
        var x = c;
        if (x == 'q') x = 'o';
        if (x == 'y') x = 'v';
        if (x == 'u') x = 'v';
        buf.write(x);
      } else if (RegExp(r'[0-9]').hasMatch(c)) {
        final d = c;
        if (d == '0') {
          buf.write('o');
        } else if (d == '1') {
          buf.write('i');
        } else if (d == '5') {
          buf.write('s');
        } else if (d == '8') {
          buf.write('b');
        } else if (d == '6') {
          buf.write('g');
        }
      }
    }
    return buf.toString();
  }

  static int _levenshtein(String a, String b) {
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
        final del = prev[j] + 1;
        final ins = curr[j - 1] + 1;
        final sub = prev[j - 1] + cost;
        curr[j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
      }
      for (var j = 0; j <= n; j++) {
        prev[j] = curr[j];
      }
    }
    return prev[n];
  }
}

class _FuzzyMatchDetail {
  _FuzzyMatchDetail({
    required this.rawOcrToken,
    required this.seedToken,
    required this.similarityScore,
    required this.reason,
  });
  final String rawOcrToken;
  final String seedToken;
  final double similarityScore;
  final String reason;
}

class _ScoreTriplet {
  _ScoreTriplet(this.raw, this.score);
  final String raw;
  final double score;
}
