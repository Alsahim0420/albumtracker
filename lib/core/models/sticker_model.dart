// ignore_for_file: constant_identifier_names

/// Tipo de lamina (modelo Qatar 2022: badge, team_photo, player).
enum StickerType {
  badge,
  team_photo,
  player,
  special,
}

/// Modelo de dominio: una lamina del álbum.
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
  String get teamCode => teamId;

  int? get localNumber {
    final parts = code.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final n = int.tryParse(parts.last);
      if (n != null) return n;
    }
    final m = RegExp(r'^[A-Z]{3}-(\d{1,2})$').firstMatch(id.toUpperCase());
    if (m != null) return int.tryParse(m.group(1)!);
    return null;
  }

  String get displayCode {
    final n = localNumber;
    if (teamCode == 'FWC' && n != null) {
      if (n == 0) return '00';
      return 'SP $n';
    }
    if (n != null) return '$teamCode $n';
    return code;
  }

  String get displayLabel {
    switch (type) {
      case StickerType.badge:
        return 'Team Emblem';
      case StickerType.team_photo:
        return 'Team Photo';
      case StickerType.player:
        return playerName ?? code;
      case StickerType.special:
        return 'Special';
    }
  }
}
