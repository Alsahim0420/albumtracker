/// Tipo de pegatina en la vista de detalle del equipo.
enum TeamStickerType { badge, photo, player }

/// Una pegatina individual en la vista de detalle del equipo (mock).
class TeamStickerItem {
  const TeamStickerItem({
    required this.code,
    required this.label,
    this.name,
    required this.type,
    required this.collected,
    this.duplicateCount = 0,
  });

  final String code;
  final String label;
  final String? name;
  final TeamStickerType type;
  final bool collected;
  final int duplicateCount;
}
