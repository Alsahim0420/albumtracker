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
    if (!_hasFifaHeader(t)) {
      return false;
    }
    if (_extractAnchoredBackCodePairs(t).isNotEmpty) return true;
    if (extractFifaStyleCodes(t).isNotEmpty) return true;
    return hasAnchoredBareSpecial00(t);
  }

  static bool _hasFifaHeader(String t) {
    return t.contains('FIFA') &&
        t.contains('WORLD') &&
        t.contains('CUP') &&
        t.contains('2026');
  }

  static final RegExp _fifaCodeLine = RegExp(
    r'\b([A-Z]{3})\s+(\d{1,2})\b',
  );

  /// `00` suelto como número de la **especial 00** (no parte de fechas/pesos).
  static final RegExp _bareSpecial00 = RegExp(r'(?<![0-9])00(?![0-9])');

  /// Códigos pegados tipo `RSA11`, `R5A17` (equipo OCR ruidoso + slot).
  static final RegExp _fifaGluedTeamDigits = RegExp(
    r'(?<![A-Z0-9])([A-Z][A-Z0-9]{2})(\d{1,2})(?![0-9])',
  );

  /// Slot de una letra tras espacio: `RSA B` → 8.
  static final RegExp _fifaSpacedLetterSlot = RegExp(
    r'\b([A-Z]{3})\s+([A-Z])\b',
  );

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
    if (!_hasFifaHeader(t)) {
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

  /// Todos los pares (equipo, número) legibles en **todo** el texto (patrón simple).
  /// Sin deduplicar: cada aparición OCR cuenta.
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
      if (n == null) continue;
      final normalizedCode = _normalizeOcrCode(a);
      if (!_isValidSlotForCode(normalizedCode, n)) continue;
      out.add((code: normalizedCode, number: n));
    }
    return out;
  }

  /// Pares en ventanas ancladas a `CUP 2026` / `WORLD CUP 2026`.
  /// Normalización agresiva **solo** aquí (R5A→RSA, pegados, slot `B`→8, etc.).
  /// **No** deduplica: misma lámina repetida en OCR → varias entradas.
  static List<({String code, int number})> extractFifaStyleCodesAnchoredNearCup2026(
    String upperNormalized,
  ) {
    if (!_hasFifaHeader(upperNormalized)) return const [];
    return _extractAnchoredBackCodePairs(upperNormalized.toUpperCase());
  }

  static List<({String code, int number})> _extractAnchoredBackCodePairs(String t) {
    final ordered = <({String code, int number})>[];
    const anchors = <String>['CUP 2026', 'WORLD CUP 2026'];
    for (final anchor in anchors) {
      var from = 0;
      while (true) {
        final i = t.indexOf(anchor, from);
        if (i < 0) break;
        final window = anchorWindowAround(t, i, anchor.length);
        ordered.addAll(_scanWindowForBackCodes(window));
        for (final _ in _bareSpecial00.allMatches(window)) {
          ordered.add((code: 'FWC', number: 0));
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
    var all = _extractAnchoredBackCodePairs(t);
    if (all.isEmpty) {
      all = extractFifaStyleCodes(t);
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
    out.addAll(_scanWindowForBackCodes(segment));
    for (final _ in _bareSpecial00.allMatches(segment)) {
      out.add((code: 'FWC', number: 0));
    }
    return out;
  }

  static bool _isValidSlotForCode(String code, int n) {
    if (code == 'FWC') {
      return n >= 0 && n <= 19;
    }
    return n >= 1 && n <= 20;
  }

  static List<({String code, int number})> _scanWindowForBackCodes(String window) {
    final hits = <_BackCodeHit>[];

    void pushHit(int start, int end, String rawFull, String rawTeam, String rawSlot) {
      hits.add(
        _BackCodeHit(
          start: start,
          end: end,
          rawFull: rawFull,
          rawTeam: rawTeam,
          rawSlot: rawSlot,
        ),
      );
    }

    for (final m in _fifaCodeLine.allMatches(window)) {
      final a = m.group(1);
      final b = m.group(2);
      if (a == null || b == null) continue;
      pushHit(m.start, m.end, m.group(0) ?? '', a, b);
    }

    for (final m in _fifaGluedTeamDigits.allMatches(window)) {
      final a = m.group(1);
      final b = m.group(2);
      if (a == null || b == null) continue;
      if (a.length != 3) continue;
      pushHit(m.start, m.end, m.group(0) ?? '', a, b);
    }

    for (final m in _fifaSpacedLetterSlot.allMatches(window)) {
      final a = m.group(1);
      final b = m.group(2);
      if (a == null || b == null) continue;
      if (int.tryParse(b) != null) continue;
      pushHit(m.start, m.end, m.group(0) ?? '', a, b);
    }

    if (hits.isEmpty) return const [];

    hits.sort((x, y) {
      final c = x.start.compareTo(y.start);
      if (c != 0) return c;
      return (y.end - y.start).compareTo(x.end - x.start);
    });

    final picked = <_BackCodeHit>[];
    var lastEnd = -1;
    for (final h in hits) {
      if (h.start < lastEnd) continue;
      picked.add(h);
      lastEnd = h.end;
    }

    final out = <({String code, int number})>[];
    for (final h in picked) {
      final pair = _pairFromBackHit(h);
      if (pair != null) {
        out.add(pair);
      }
    }
    return out;
  }

  static ({String code, int number})? _pairFromBackHit(_BackCodeHit h) {
    final teamNorm = _normalizeBackTeamOcr(h.rawTeam);
    final code = _normalizeOcrCode(teamNorm);
    if (code != 'FWC' && !_knownTeamCodes.contains(code)) {
      return null;
    }
    final slot = _parseBackSlotOcr(h.rawSlot);
    if (slot == null) {
      return null;
    }
    if (!_isValidSlotForCode(code, slot)) {
      return null;
    }
    return (code: code, number: slot);
  }

  /// Solo reverso anclado: `5`→`S` en token de 3 letras si forma código FIFA válido.
  static String _normalizeBackTeamOcr(String rawTeam) {
    final up = rawTeam.toUpperCase();
    if (up.length != 3) return up;
    if (_knownTeamCodes.contains(up)) return up;
    final allFiveToS = up.replaceAll('5', 'S');
    if (_knownTeamCodes.contains(allFiveToS)) return allFiveToS;
    return up;
  }

  /// Parte numérica del reverso (incl. `B`→`8`, OCR en slot).
  static int? _parseBackSlotOcr(String rawSlot) {
    final s = rawSlot.trim().toUpperCase();
    if (s.isEmpty) return null;
    if (RegExp(r'^\d{1,2}$').hasMatch(s)) {
      return int.tryParse(s);
    }
    if (s.length == 1) {
      final mapped = _mapLetterSlotToDigit(s);
      if (mapped == null) return null;
      return int.tryParse(mapped);
    }
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      if (RegExp(r'[0-9]').hasMatch(ch)) {
        buf.write(ch);
      } else {
        final d = _mapLetterSlotToDigit(ch);
        if (d == null) return null;
        buf.write(d);
      }
    }
    return int.tryParse(buf.toString());
  }

  /// Mapeo conservador en **slot** (contexto reverso anclado 2026).
  static String? _mapLetterSlotToDigit(String ch) {
    switch (ch) {
      case 'B':
        return '8';
      case 'O':
      case 'Q':
        return '0';
      case 'I':
      case 'L':
        return '1';
      case 'Z':
        return '2';
      case 'A':
        return '4';
      default:
        return null;
    }
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

class _BackCodeHit {
  const _BackCodeHit({
    required this.start,
    required this.end,
    required this.rawFull,
    required this.rawTeam,
    required this.rawSlot,
  });

  final int start;
  final int end;
  final String rawFull;
  final String rawTeam;
  final String rawSlot;
}
