/// Extrae solo códigos estructurados de reverso (sin números sueltos tipo fecha/peso).
class BackStickerCodeParser {
  static final RegExp _hyphenCode = RegExp(
    r'\b[A-Z]{2,4}(?:-[A-Z0-9]{1,4}){1,3}\b',
  );
  static final RegExp _letterDigit = RegExp(r'\b[A-Z]\d{1,2}\b');
  /// Panini suele imprimir el código como `ARG 20` (con espacio), no `ARG20`.
  static final RegExp _teamSpaceDigits = RegExp(r'\b([A-Z]{3})\s+(\d{1,2})\b');
  static final RegExp _teamDigits = RegExp(r'\b([A-Z]{3})(\d{2})\b');
  static final RegExp _teamOneOrTwoDigits = RegExp(r'\b([A-Z]{3})(\d{1,2})\b');

  /// Candidatos ordenados: primero códigos con guiones (más específicos), luego el resto.
  List<String> extractStructuredCodes(String normalizedUpperText) {
    final seen = <String>{};
    final ordered = <String>[];

    void add(String? s) {
      if (s == null || s.isEmpty) return;
      if (seen.add(s)) ordered.add(s);
    }

    final hyphenMatches = _hyphenCode
        .allMatches(normalizedUpperText)
        .map((m) => m.group(0)!)
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final h in hyphenMatches) {
      add(h);
    }

    for (final m in _letterDigit.allMatches(normalizedUpperText)) {
      add(m.group(0));
    }

    for (final m in _teamSpaceDigits.allMatches(normalizedUpperText)) {
      final team = m.group(1)!;
      final n = m.group(2)!;
      final padded = n.length == 1 ? n.padLeft(2, '0') : n;
      add('$team-$padded');
      add('$team-PL-$padded');
    }

    for (final m in _teamDigits.allMatches(normalizedUpperText)) {
      final team = m.group(1)!;
      final n = m.group(2)!;
      add('$team-$n');
      add('$team-PL-$n');
    }
    for (final m in _teamOneOrTwoDigits.allMatches(normalizedUpperText)) {
      final team = m.group(1)!;
      final n = m.group(2)!;
      if (n.length == 1) {
        final padded = n.padLeft(2, '0');
        add('$team-$padded');
        add('$team-PL-$padded');
      }
    }

    return ordered;
  }
}
