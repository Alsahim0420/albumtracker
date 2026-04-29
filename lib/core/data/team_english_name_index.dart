import 'package:albumtracker/core/data/world_cup_2026_seed.dart';

/// Nombres de países en el seed (en inglés) → código de equipo 3 letras.
/// Uso: "WE ARE PORTUGAL" → "POR".
class TeamEnglishNameIndex {
  TeamEnglishNameIndex._();

  static List<({String fifa, String nameUpper})>? _byLength;

  static void _ensure() {
    _byLength ??= () {
      final out = <({String fifa, String nameUpper})>[];
      for (final g in WorldCup2026Seed.groups) {
        for (final t in g.teams) {
          out.add((
            fifa: t.id,
            nameUpper: t.name.toUpperCase().trim().replaceAll(RegExp(r'\s+'), ' '),
          ),);
        }
      }
      out.sort((a, b) => b.nameUpper.length.compareTo(a.nameUpper.length));
      return out;
    }();
  }

  static String? teamCodeForEnglishCountryName(String ocrNameFragment) {
    if (ocrNameFragment.isEmpty) return null;
    _ensure();
    var key = ocrNameFragment
        .toUpperCase()
        .trim()
        .replaceAll(RegExp(r'[^A-Z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (key.contains('KOREA')) {
      key = key
          .replaceAll('KOREA REPUBLIC', 'SOUTH KOREA')
          .replaceAll('KOREA, REPUBLIC OF', 'SOUTH KOREA');
    }
    final a = _alias[key];
    if (a != null) return a;
    for (final e in _byLength!) {
      if (key == e.nameUpper) return e.fifa;
      if (key.contains(e.nameUpper)) return e.fifa;
    }
    return null;
  }

  /// Extrae todos los códigos de equipo detectados en un bloque OCR.
  /// Útil para evitar falsos positivos cuando hay múltiples láminas en una misma foto.
  static Set<String> countryCodesInText(String normalizedUpperText) {
    final out = <String>{};
    if (normalizedUpperText.isEmpty) return out;
    _ensure();
    final key = normalizedUpperText
        .toUpperCase()
        .trim()
        .replaceAll(RegExp(r'[^A-Z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (key.isEmpty) return out;
    for (final e in _byLength!) {
      if (key == e.nameUpper || key.contains(e.nameUpper)) {
        out.add(e.fifa);
      }
    }
    for (final entry in _alias.entries) {
      if (key.contains(entry.key)) {
        out.add(entry.value);
      }
    }
    return out;
  }

  /// [normalizedUpperText] = línea o bloque normalizado (mayúsculas, un espacio).
  static String? fromWeAreLine(String normalizedUpperText) {
    final t = normalizedUpperText.toUpperCase();
    final normalized = t
        .replaceAll(RegExp(r'[^A-Z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return null;

    // OCR suele unir/separar o deformar: WEAR, WEARE, WE AR, WEA R, W EAR, etc.
    final unified = normalized
        .replaceAll(RegExp(r'\bWEA?R\b'), 'WE ARE')
        .replaceAll(RegExp(r'\bWEARE\b'), 'WE ARE')
        .replaceAll(RegExp(r'\bW\s*E\s*A\s*R\s*E?\b'), 'WE ARE')
        .replaceAll(RegExp(r'\bW[E3][A4]R[E3]?\b'), 'WE ARE')
        .replaceAll(RegExp(r'\bWE\s+AR\b'), 'WE ARE');

    final compact = unified.replaceAll(' ', '');
    final hasWeAreSignal =
        unified.contains('WE ARE') ||
        compact.contains('WEARE') ||
        compact.contains('WEAR');
    if (!hasWeAreSignal) return null;

    var rest = _tailAfterWeAre(unified) ?? '';
    rest = rest
        .replaceAll(RegExp(r'[^A-Z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (rest.isEmpty) {
      // Fallback cuando viene pegado (ej. WEARMEXIGO / WEARESPAIN).
      rest = compact
          .replaceFirst(RegExp(r'^WEARE'), '')
          .replaceFirst(RegExp(r'^WEAR'), '')
          .trim();
      if (rest.isEmpty) rest = unified;
    }
    _ensure();
    for (final e in _byLength!) {
      if (rest == e.nameUpper) return e.fifa;
      if (rest.startsWith('${e.nameUpper} ')) return e.fifa;
      if (rest.startsWith(e.nameUpper) && rest.length == e.nameUpper.length) {
        return e.fifa;
      }
      if (rest.contains(e.nameUpper)) return e.fifa;
      if (rest.contains(e.nameUpper.replaceAll(' ', ''))) return e.fifa;
    }
    final exact = teamCodeForEnglishCountryName(rest);
    if (exact != null) return exact;
    return _fuzzyCountryFromText(rest);
  }

  static String? _tailAfterWeAre(String text) {
    final m = RegExp(r'\bWE\s*AR[E]?\s*').firstMatch(text);
    if (m == null) return null;
    return text.substring(m.end);
  }

  static String? _fuzzyCountryFromText(String text) {
    _ensure();
    final normalized = text
        .replaceAll(RegExp(r'[^A-Z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final tokens = normalized
        .split(' ')
        .where((w) => w.length >= 4)
        .toList(growable: false);
    final candidates = <String>[
      normalized.replaceAll(' ', ''),
      ...tokens,
    ];

    String? bestFifa;
    var bestScore = 0.0;
    for (final probe in candidates) {
      if (probe.isEmpty) continue;
      for (final e in _byLength!) {
        final candidate = e.nameUpper;
        final candidateCompact = candidate.replaceAll(' ', '');
        final score = _normalizedSimilarity(probe, candidateCompact);
        if (score > bestScore) {
          bestScore = score;
          bestFifa = e.fifa;
        }
      }
    }
    // Tolera OCR tipo MEXIGO->MEXICO, pero evita falsos positivos muy débiles.
    if (bestScore >= 0.72) return bestFifa;
    return null;
  }

  static double _normalizedSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;
    final d = _levenshteinDistance(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) return 0;
    final v = 1.0 - (d / maxLen);
    if (v < 0) return 0;
    if (v > 1) return 1;
    return v;
  }

  static int _levenshteinDistance(String a, String b) {
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

  static const _alias = <String, String>{
    'COTE D IVOIRE': 'CIV',
    'FCF': 'CPV',
    'SENEG LAISE': 'SEN',
    'SENEGALAISE': 'SEN',
    'FEDERATION SENEGALAISE DE FOOTBALL': 'SEN',
  };
}
