/// Extrae identificadores de texto OCR: números globales, códigos tipo `ARG-PL-01`
/// y códigos de reverso de ediciones previas (`C1`, `F12`, etc.).
class StickerTextParser {
  static final RegExp _numericPattern = RegExp(r'\b\d{1,4}\b');
  static final RegExp _alphaNumericPattern = RegExp(
    r'\b[A-Z]{2,4}(?:-[A-Z0-9]{1,4}){1,3}\b',
  );

  /// Códigos de una letra + dígitos (reverso lámina Qatar 2022: C1, C2, …).
  static final RegExp _letterDigitCode = RegExp(r'\b[A-Z]\d{1,2}\b');

  /// OCR a veces separa: "C 1" → fusionar a C1.
  static final RegExp _spacedLetterDigit = RegExp(r'\b([A-Z])\s+(\d{1,2})\b');

  String normalizeRawText(String rawText) {
    final upper = rawText.toUpperCase().replaceAll('\n', ' ');
    final cleaned = upper.replaceAll(RegExp(r'[^A-Z0-9\-\s]'), ' ');
    final tokens = cleaned
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty);
    final normalizedTokens = tokens.map(_fixOcrToken).toList();
    return normalizedTokens.join(' ').trim();
  }

  /// Orden: primero códigos letra+dígito (evita confundir "3" de +3 con número global 3),
  /// luego códigos con guiones y por último números (globales largos antes que cortos).
  /// No se infieren códigos `XXXNN` pegados: el álbum usa `XXX NN` con espacio.
  List<String> extractCandidates(String normalizedText) {
    final seen = <String>{};
    final ordered = <String>[];

    void add(String? s) {
      if (s == null || s.isEmpty) return;
      if (seen.add(s)) ordered.add(s);
    }

    for (final match in _letterDigitCode.allMatches(normalizedText)) {
      add(match.group(0));
    }
    for (final match in _spacedLetterDigit.allMatches(normalizedText)) {
      add('${match.group(1)}${match.group(2)}');
    }
    for (final match in _alphaNumericPattern.allMatches(normalizedText)) {
      add(match.group(0));
    }

    final numericHits = _numericPattern
        .allMatches(normalizedText)
        .map((m) => m.group(0)!)
        .toList();

    numericHits.sort((a, b) {
      final la = a.length;
      final lb = b.length;
      if (la != lb) return lb.compareTo(la);
      final ia = int.tryParse(a) ?? 0;
      final ib = int.tryParse(b) ?? 0;
      return ib.compareTo(ia);
    });
    for (final n in numericHits) {
      add(n);
    }

    return ordered;
  }

  String _fixOcrToken(String token) {
    if (!RegExp(r'\d').hasMatch(token)) return token;
    return token
        .replaceAll('O', '0')
        .replaceAll('I', '1')
        .replaceAll('S', '5')
        .replaceAll('B', '8');
  }
}
