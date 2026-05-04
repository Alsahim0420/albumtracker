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
  /// al menos un código de equipo+número legible de reverso (ej. "POR 11"),
  /// o la especial **00** anclada junto al pie FIFA (sin patrón `XXX NN`).
  static bool isFifaWorldCup2026BackText(String upperNormalized) {
    final t = upperNormalized.toUpperCase();
    if (!(t.contains('FIFA') &&
        t.contains('WORLD') &&
        t.contains('CUP') &&
        t.contains('2026'))) {
      return false;
    }
    if (extractFifaStyleCodes(t).isNotEmpty) return true;
    return hasAnchoredBareSpecial00(t);
  }

  static final RegExp _fifaCodeLine = RegExp(
    r'\b([A-Z]{3})\s+(\d{1,2})\b',
  );

  /// `00` suelto como número de la **especial 00** (no parte de fechas/pesos).
  static final RegExp _bareSpecial00 = RegExp(r'(?<![0-9])00(?![0-9])');

  /// Ventana **±240** caracteres alrededor del índice del ancla (incluye códigos
  /// impresos antes del pie FIFA, p. ej. `SUI 1` ... `CUP 2026` ... `ECU 1`).
  static String anchorWindowAround(String fullUpper, int anchorIndex, int anchorLength) {
    final t = fullUpper;
    final len = t.length;
    final start = (anchorIndex - 240).clamp(0, len);
    final end = (anchorIndex + anchorLength + 240).clamp(0, len);
    return t.substring(start, end);
  }

  /// `00` anclado cerca de `CUP 2026` / `WORLD CUP 2026` (ventana simétrica).
  static bool hasAnchoredBareSpecial00(String upperNormalized) {
    final t = upperNormalized.toUpperCase();
    if (!(t.contains('FIFA') &&
        t.contains('WORLD') &&
        t.contains('CUP') &&
        t.contains('2026'))) {
      return false;
    }
    const anchors = <String>['CUP 2026', 'WORLD CUP 2026'];
    for (final anchor in anchors) {
      var from = 0;
      while (true) {
        final i = t.indexOf(anchor, from);
        if (i < 0) break;
        final window = anchorWindowAround(t, i, anchor.length);
        if (_bareSpecial00.hasMatch(window)) {
          return true;
        }
        from = i + anchor.length;
      }
    }
    return false;
  }

  /// Todos los pares (equipo, número) legibles, por orden de aparición.
  /// Incluye `FWC 0`…`FWC 19` (especiales); **no** incluye `00` suelto (solo anclado).
  static List<({String code, int number})> extractFifaStyleCodes(
    String upperNormalized,
  ) {
    final t = upperNormalized.toUpperCase();
    final out = <({String code, int number})>[];
    final seen = <String>{};
    void add(String code, int number) {
      final key = '$code-$number';
      if (!seen.add(key)) return;
      out.add((code: code, number: number));
    }

    for (final m in _fifaCodeLine.allMatches(t)) {
      final a = m.group(1);
      final b = m.group(2);
      if (a == null || b == null) continue;
      final n = int.tryParse(b);
      if (n == null) continue;
      final normalizedCode = _normalizeOcrCode(a);
      if (normalizedCode == 'FWC') {
        if (n < 0 || n > 19) continue;
      } else {
        if (n < 1 || n > 20) continue;
      }
      add(normalizedCode, n);
    }
    return out;
  }

  /// Solo pares `XXX NN` en ventana **±240** caracteres alrededor de `CUP 2026` /
  /// `WORLD CUP 2026` (códigos antes o después del pie). Evita ruido lejos del ancla.
  static List<({String code, int number})> extractFifaStyleCodesAnchoredNearCup2026(
    String upperNormalized,
  ) {
    if (!isFifaWorldCup2026BackText(upperNormalized)) return const [];
    final t = upperNormalized.toUpperCase();
    final ordered = <({String code, int number})>[];
    final seen = <String>{};

    void addPair(String rawCode, int number) {
      final code = _normalizeOcrCode(rawCode);
      final key = '$code-$number';
      if (!seen.add(key)) return;
      ordered.add((code: code, number: number));
    }

    const anchors = <String>['CUP 2026', 'WORLD CUP 2026'];
    for (final anchor in anchors) {
      var from = 0;
      while (true) {
        final i = t.indexOf(anchor, from);
        if (i < 0) break;
        final window = anchorWindowAround(t, i, anchor.length);
        for (final m in _fifaCodeLine.allMatches(window)) {
          final a = m.group(1);
          final b = m.group(2);
          if (a == null || b == null) continue;
          final n = int.tryParse(b);
          if (n == null) continue;
          final c = _normalizeOcrCode(a);
          if (c == 'FWC') {
            if (n < 0 || n > 19) continue;
          } else {
            if (n < 1 || n > 20) continue;
          }
          addPair(a, n);
        }
        if (_bareSpecial00.hasMatch(window)) {
          addPair('FWC', 0);
        }
        from = i + anchor.length;
      }
    }

    return ordered;
  }

  /// Código cerca del pie de "WORLD CUP 2026" (misma línea lógica tras normalizar).
  static ({String code, int number})? pickCodeNearFifaFooter(
    String upperNormalized,
  ) {
    if (!isFifaWorldCup2026BackText(upperNormalized)) return null;
    final t = upperNormalized.toUpperCase();
    var all = extractFifaStyleCodes(t);
    if (all.isEmpty) {
      all = extractFifaStyleCodesAnchoredNearCup2026(t);
    }
    if (all.isEmpty) return null;
    const cupAnchor = 'CUP 2026';
    final cupIdx = t.indexOf(cupAnchor);
    final int idx;
    final int anchorLen;
    if (cupIdx >= 0) {
      idx = cupIdx;
      anchorLen = cupAnchor.length;
    } else {
      final y = t.indexOf('2026');
      if (y < 0) {
        return all.last;
      }
      idx = y;
      anchorLen = 4;
    }
    final segment = anchorWindowAround(t, idx, anchorLen);
    final fromPairs = _footerSegmentPairs(segment);
    if (fromPairs.isNotEmpty) {
      return fromPairs.last;
    }
    return all.last;
  }

  /// Pares `XXX NN` / `FWC N` / especial **00** suelta en un segmento de pie de reverso.
  static List<({String code, int number})> _footerSegmentPairs(String segment) {
    final out = <({String code, int number})>[];
    for (final m in _fifaCodeLine.allMatches(segment)) {
      final a = m.group(1);
      final b = m.group(2);
      if (a == null || b == null) continue;
      final n = int.tryParse(b);
      if (n == null) continue;
      final c = _normalizeOcrCode(a);
      if (c == 'FWC') {
        if (n < 0 || n > 19) continue;
      } else {
        if (n < 1 || n > 20) continue;
      }
      out.add((code: c, number: n));
    }
    if (_bareSpecial00.hasMatch(segment)) {
      out.add((code: 'FWC', number: 0));
    }
    return out;
  }

  static String _normalizeOcrCode(String rawCode) {
    final up = rawCode.toUpperCase();
    if (up == 'FWC') return 'FWC';
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
