// ignore_for_file: constant_identifier_names

/// Tipo de pegatina (modelo Qatar 2022: badge, team_photo, player).
enum StickerType {
  badge,
  team_photo,
  player,
}

/// Modelo de dominio: una pegatina del álbum.
class StickerModel {
  const StickerModel({
    required this.id,
    required this.code,
    required this.type,
    this.playerName,
    required this.teamId,
    this.globalNumber,
  });

  final String id;
  final String code;
  final StickerType type;
  final String? playerName;
  final String teamId;
  /// Número global en el álbum (1..960 para team stickers), usado en bulk add.
  final int? globalNumber;

  String get displayLabel {
    switch (type) {
      case StickerType.badge:
        return 'Team Badge';
      case StickerType.team_photo:
        return 'Team Photo';
      case StickerType.player:
        return playerName ?? code;
    }
  }
}
