/// Tipo de lamina en la vista de detalle del equipo.
enum TeamStickerType { badge, photo, player, special }

/// Una lamina individual en la vista de detalle del equipo (mock).
class TeamStickerItem {
  const TeamStickerItem({
    required this.code,
    required this.displayCode,
    this.globalNumber,
    required this.label,
    this.name,
    required this.type,
    required this.collected,
    this.duplicateCount = 0,
  });

  final String code;
  /// Código visible local por equipo (p. ej. "RSA 13", "URU 1").
  final String displayCode;
  /// Número global del álbum (1..960); solo uso interno.
  final int? globalNumber;
  final String label;
  final String? name;
  final TeamStickerType type;
  final bool collected;
  final int duplicateCount;
}
