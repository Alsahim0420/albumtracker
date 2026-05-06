import 'dart:math' as math;

import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/models/team_model.dart';

/// Índice genérico para relacionar texto OCR de escudos (sin código FIFA seguro)
/// con un equipo del seed: país en inglés (dato seed), español localizado y alias mínimos.
abstract final class SeedTeamBadgeMatchIndex {
  SeedTeamBadgeMatchIndex._();

  /// Similitud mínima (Levenshtein normalizado u otros boosts internos) para aceptar.
  static const double minAcceptScore = 0.82;

  /// El segundo mejor no debe quedar a menos de esta distancia del primero.
  static const double minWinnerGap = 0.03;

  static List<_BadgeTeamRow>? _rows;

  /// Coincidencia única; si hay empate o candidatos demasiado cercanos, [ambiguous]=true.
  static BadgeHaystackMatch matchNormalizedHaystack(String normalizedHaystack) {
    final h = normalizedHaystack.trim();
    if (h.isEmpty) {
      return const BadgeHaystackMatch.none();
    }
    _ensureRows();

    final scored = <({String fifa, double score})>[];
    for (final row in _rows!) {
      final s = row.bestScoreAgainst(h);
      scored.add((fifa: row.fifa, score: s));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final best = scored.first;
    if (best.score < minAcceptScore) {
      return const BadgeHaystackMatch.none();
    }
    if (scored.length >= 2) {
      final second = scored[1];
      if (best.score - second.score < minWinnerGap) {
        return BadgeHaystackMatch.ambiguous();
      }
    }
    return BadgeHaystackMatch.ok(best.fifa);
  }

  static void _ensureRows() {
    _rows ??= () {
      final out = <_BadgeTeamRow>[];
      for (final g in WorldCup2026Seed.groups) {
        for (final t in g.teams) {
          out.add(_BadgeTeamRow.fromTeam(t));
        }
      }
      return out;
    }();
  }
}

class BadgeHaystackMatch {
  const BadgeHaystackMatch._(this.fifa, this.ambiguous);

  const BadgeHaystackMatch.none() : this._(null, false);

  const BadgeHaystackMatch.ambiguous() : this._(null, true);

  const BadgeHaystackMatch.ok(String fifa) : this._(fifa, false);

  final String? fifa;
  final bool ambiguous;
}

class _BadgeTeamRow {
  _BadgeTeamRow(this.fifa, this.phrases);

  final String fifa;
  final List<String> phrases;

  factory _BadgeTeamRow.fromTeam(TeamModel t) {
    final fifa = t.id;
    final englishKey = t.name;
    final phrases = <String>{};

    void addPhrase(String raw) {
      final n = WorldCup2026Seed.normalizeTextForPlayerNameMatch(raw);
      if (n.isEmpty) return;
      phrases.add(n);
      final compact = n.replaceAll(RegExp(r'\s+'), '');
      if (compact.length >= 3) phrases.add(compact);
    }

    addPhrase(englishKey);
    final es = kSpanishCountryDisplayByEnglishSeedKey[englishKey];
    if (es != null && es.trim().isNotEmpty) {
      addPhrase(es);
    }

    final extras = kBadgePhraseComplementByFifa[fifa];
    if (extras != null) {
      for (final e in extras) {
        addPhrase(e);
      }
    }

    addPhrase(fifa);

    return _BadgeTeamRow(fifa, phrases.toList()..sort((a, b) => b.length.compareTo(a.length)));
  }

  double bestScoreAgainst(String haystack) {
    var best = 0.0;
    for (final p in phrases) {
      final s = _scoreHaystackPhrase(haystack, p);
      if (s > best) best = s;
    }
    return best;
  }
}

double _scoreHaystackPhrase(String h, String p) {
  if (h.isEmpty || p.isEmpty) return 0;
  if (h == p) return 1;
  if (p.length >= 4 && h.contains(p)) return math.max(0.92, _normalizedLevenshteinSimilarity(h, p));
  if (h.length >= 4 && p.contains(h)) {
    return math.max(0.88, _normalizedLevenshteinSimilarity(h, p));
  }

  final ht = h.split(' ').where((t) => t.length >= 4).toList();
  final pt = p.split(' ').where((t) => t.length >= 3).toList();
  var tokenBoost = 0.0;
  for (final tok in pt) {
    if (tok.length >= 5 && h.contains(tok)) {
      tokenBoost = math.max(tokenBoost, 0.9);
    }
    for (final probe in ht) {
      tokenBoost = math.max(
        tokenBoost,
        _normalizedLevenshteinSimilarity(probe, tok),
      );
    }
  }

  final lev = _normalizedLevenshteinSimilarity(h, p);
  return math.max(lev, tokenBoost);
}

double _normalizedLevenshteinSimilarity(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 1;
  if (a.isEmpty || b.isEmpty) return 0;
  final maxLen = math.max(a.length, b.length);
  final dist = _levenshteinDistance(a, b);
  return 1.0 - dist / maxLen;
}

int _levenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var previous = List<int>.generate(b.length + 1, (j) => j);
  var current = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    final ai = a.codeUnitAt(i - 1);
    for (var j = 1; j <= b.length; j++) {
      final cost = ai == b.codeUnitAt(j - 1) ? 0 : 1;
      current[j] = math.min(
        math.min(current[j - 1] + 1, previous[j] + 1),
        previous[j - 1] + cost,
      );
    }
    final tmp = previous;
    previous = current;
    current = tmp;
  }
  return previous[b.length];
}

/// Español de UI (`assets/lang/es.json`) alineado con la clave en inglés del seed [TeamModel.name].
const Map<String, String> kSpanishCountryDisplayByEnglishSeedKey = {
  'Mexico': 'México',
  'South Korea': 'Corea del Sur',
  'South Africa': 'Sudáfrica',
  'Czech Republic': 'República Checa',
  'Canada': 'Canadá',
  'Switzerland': 'Suiza',
  'Qatar': 'Qatar',
  'Bosnia and Herzegovina': 'Bosnia y Herzegovina',
  'Brazil': 'Brasil',
  'Morocco': 'Marroco',
  'Scotland': 'Escocia',
  'Haiti': 'Haití',
  'USA': 'Estados Unidos',
  'Paraguay': 'Paraguay',
  'Australia': 'Australia',
  'Turkey': 'Turquía',
  'Germany': 'Alemania',
  'Ecuador': 'Ecuador',
  'Ivory Coast': 'Costa de Marfil',
  'Curaçao': 'Curaçao',
  'Netherlands': 'Países Bajos',
  'Japan': 'Japón',
  'Tunisia': 'Túnez',
  'Sweden': 'Suecia',
  'Belgium': 'Bélgica',
  'Iran': 'Irán',
  'Egypt': 'Egipto',
  'New Zealand': 'Nueva Zelanda',
  'Spain': 'España',
  'Uruguay': 'Uruguay',
  'Saudi Arabia': 'Arabia Saudita',
  'Cape Verde': 'Cabo Verde',
  'France': 'Francia',
  'Senegal': 'Senegal',
  'Norway': 'Noruega',
  'Iraq': 'Irak',
  'Argentina': 'Argentina',
  'Austria': 'Austria',
  'Algeria': 'Argelia',
  'Jordan': 'Jordania',
  'Portugal': 'Portugal',
  'Colombia': 'Colombia',
  'Costa Rica': 'Costa Rica',
  'Uzbekistan': 'Uzbekistán',
  'DR Congo': 'República Democrática del Congo',
  'England': 'Inglaterra',
  'Croatia': 'Croacia',
  'Panama': 'Panamá',
  'Ghana': 'Ghana',
};

/// Complemento manual pequeño (demónimos, siglas habituales OCR); no sustituye al índice principal.
const Map<String, List<String>> kBadgePhraseComplementByFifa = {
  'CIV': ['Ivory Coast', 'Cote d Ivoire'],
  'COL': ['Colombiana'],
  'BEL': ['Belgian', 'Royal Belgian'],
  'SEN': ['Senegalaise', 'Senegalese'],
};
