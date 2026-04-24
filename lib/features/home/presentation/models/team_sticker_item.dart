/// Tipo de lamina en la vista de detalle del equipo.
enum TeamStickerType { badge, photo, player }

/// Una lamina individual en la vista de detalle del equipo (mock).
class TeamStickerItem {
  const TeamStickerItem({
    required this.code,
    this.globalNumber,
    required this.label,
    this.name,
    required this.type,
    required this.collected,
    this.duplicateCount = 0,
  });

  final String code;
  /// Número global del álbum (1..960); único valor numérico visible para la lámina.
  final int? globalNumber;
  final String label;
  final String? name;
  final TeamStickerType type;
  final bool collected;
  final int duplicateCount;
}
