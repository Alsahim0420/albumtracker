import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:albumtracker/core/data/shield_assets.dart';
import 'package:albumtracker/core/data/world_cup_2026_seed.dart';

/// Ruta de bandera del [TeamModel] para una lámina; respaldo al mapa de escudos.
String? albumBadgeFlagAssetPathForStickerId(String stickerId) {
  final s = WorldCup2026Seed.getStickerById(stickerId);
  if (s == null) {
    return getShieldAssetPath(teamCodeFromStickerId(stickerId));
  }
  final team = WorldCup2026Seed.getTeamById(s.teamId);
  return team?.flagAssetPath ?? getShieldAssetPath(s.teamId);
}

/// Bandera tenue a pantalla completa + código centrado (p. ej. MEX 1).
class AlbumBadgeFlagWithCenteredCode extends StatelessWidget {
  const AlbumBadgeFlagWithCenteredCode({
    super.key,
    required this.assetPath,
    required this.code,
    required this.codeStyle,
  });

  final String assetPath;
  final String code;
  final TextStyle codeStyle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        AlbumBadgeFlagHero(assetPath: assetPath),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              code,
              style: codeStyle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bandera de insignia: solo la capa tenue a pantalla completa (rectángulo, sin recorte redondo).
class AlbumBadgeFlagHero extends StatelessWidget {
  const AlbumBadgeFlagHero({
    super.key,
    required this.assetPath,
    this.backgroundOpacity = 0.12,
  });

  final String assetPath;
  final double backgroundOpacity;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        // Un poco más pequeña que el hueco y centrada (sin scale >1 que “sube” el texto).
        final fw = w * 0.96;
        final fh = h * 0.96;
        return Center(
          child: Opacity(
            opacity: backgroundOpacity,
            child: SizedBox(
              width: fw,
              height: fh,
              child: _AlbumFlagAsset(
                assetPath,
                width: fw,
                height: fh,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AlbumFlagAsset extends StatelessWidget {
  const _AlbumFlagAsset(
    this.assetPath, {
    required this.width,
    required this.height,
  });

  final String assetPath;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        fit: BoxFit.contain,
        width: width,
        height: height,
      );
    }
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      width: width,
      height: height,
    );
  }
}
