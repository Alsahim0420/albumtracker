import 'package:albumtracker/core/data/world_cup_2026_seed.dart';

/// Reverso: texto de cabecera 2026 con código "POR 11".
class Fifa2026BackOcrParser {
  static const Map<String, String> _ocrCodeAliases = {
    // Error OCR frecuente en esta colección: QAT se lee como OAT.
    'OAT': 'QAT',
  };
  static final Set<String> _knownTeamCodes = _buildKnownTeamCodes();

  /// Acepta variantes de OCR: espacios, saltos.
  /// Para evitar falsos positivos en anverso (escudos/fotos), exige también
  /// al menos un código de equipo+número legible de reverso (ej. "POR 11").
  static bool isFifaWorldCup2026BackText(String upperNormalized) {
    final t = upperNormalized.toUpperCase();
    if (!(t.contains('FIFA') &&
        t.contains('WORLD') &&
        t.contains('CUP') &&
        t.contains('2026'))) {
      return false;
    }
    return extractFifaStyleCodes(t).isNotEmpty;
  }

  static final RegExp _fifaCodeLine = RegExp(
    r'\b([A-Z]{3})\s+(\d{1,2})\b',
  );

  /// Todos los pares (equipo, número) legibles, por orden de aparición.
  static List<({String code, int number})> extractFifaStyleCodes(
    String upperNormalized,
  ) {
    final t = upperNormalized.toUpperCase();
    final out = <({String code, int number})>[];
    for (final m in _fifaCodeLine.allMatches(t)) {
      final a = m.group(1);
      final b = m.group(2);
      if (a == null || b == null) continue;
      final n = int.tryParse(b);
      if (n == null || n < 1 || n > 20) continue;
      final normalizedCode = _normalizeOcrCode(a);
      out.add((code: normalizedCode, number: n));
    }
    return out;
  }

  /// Código cerca del pie de "WORLD CUP 2026" (misma línea lógica tras normalizar).
  static ({String code, int number})? pickCodeNearFifaFooter(
    String upperNormalized,
  ) {
    if (!isFifaWorldCup2026BackText(upperNormalized)) return null;
    final t = upperNormalized.toUpperCase();
    final all = extractFifaStyleCodes(t);
    if (all.isEmpty) return null;
    const anchor = 'CUP 2026';
    var idx = t.indexOf(anchor);
    if (idx < 0) idx = t.indexOf('2026');
    if (idx < 0) {
      return all.last;
    }
    final fromAnchor = t.substring(idx);
    final fromMatches = _fifaCodeLine.allMatches(fromAnchor).toList();
    if (fromMatches.isNotEmpty) {
      final m = fromMatches.last;
      final a = m.group(1);
      final b = m.group(2);
      if (a != null && b != null) {
        final n = int.tryParse(b);
        if (n != null && n >= 1 && n <= 20) {
          return (code: _normalizeOcrCode(a), number: n);
        }
      }
    }
    return all.last;
  }

  static String _normalizeOcrCode(String rawCode) {
    final up = rawCode.toUpperCase();
    final aliased = _ocrCodeAliases[up] ?? up;
    if (_knownTeamCodes.contains(aliased)) return aliased;

    // Autocorrección OCR: si hay exactamente 1 candidato válido a distancia 1,
    // lo adoptamos (ej.: GAE->GRE, MEO->MEX, OAT->QAT).
    String? uniqueCandidate;
    for (final code in _knownTeamCodes) {
      if (_charDiffCount(aliased, code) <= 1) {
        if (uniqueCandidate == null) {
          uniqueCandidate = code;
        } else if (uniqueCandidate != code) {
          // Ambiguo: preferimos no inventar.
          return aliased;
        }
      }
    }
    return uniqueCandidate ?? aliased;
  }

  static int _charDiffCount(String a, String b) {
    if (a.length != b.length) return 999;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      if (a.codeUnitAt(i) != b.codeUnitAt(i)) {
        diff++;
      }
    }
    return diff;
  }

  static Set<String> _buildKnownTeamCodes() {
    final out = <String>{};
    for (final group in WorldCup2026Seed.groups) {
      for (final team in group.teams) {
        final id = team.id.toUpperCase();
        if (id.length == 3) out.add(id);
      }
    }
    return out;
  }
}
