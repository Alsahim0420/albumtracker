import 'sticker_model.dart';
import 'package:flutter/material.dart';

/// Modelo de dominio: un equipo del Mundial 2026.
class TeamModel {
  const TeamModel({
    required this.id,
    required this.name,
    required this.groupId,
    required this.flagAssetPath,
    required this.stickers,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String id;
  final String name;
  final String groupId;
  /// Ruta al asset de bandera, ej. assets/flags/us.svg
  final String? flagAssetPath;
  final List<StickerModel> stickers;
  final Color primaryColor;
  final Color secondaryColor;

  int get totalStickers => stickers.length;
}
