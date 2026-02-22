// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Muestra bandera por asset path (assets/flags/xx.svg) o por código (colores).
class FlagPlaceholder extends StatelessWidget {
  const FlagPlaceholder({super.key, required this.code});

  /// Código 3 letras (USA, MEX) para colores, o ruta de asset (assets/flags/us.svg).
  final String code;

  @override
  Widget build(BuildContext context) {
    if (code.startsWith('assets/')) {
      if (code.endsWith('.svg')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SvgPicture.asset(code),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Image.asset(
          code,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _colorFallback(code),
        ),
      );
    }
    final colors = _colorsForCode(code);
    if (colors.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: colors
            .map((c) => Container(width: 6, height: 16, color: c))
            .toList(),
      ),
    );
  }

  Widget _colorFallback(String path) {
    final colors = _colorsForCode(path);
    if (colors.isEmpty) return Container(color: Colors.grey.shade700, width: 32, height: 24);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: colors.map((c) => Container(width: 6, height: 16, color: c)).toList(),
      ),
    );
  }

  static List<Color> _colorsForCode(String code) {
    final upper = code.length > 4 ? code : code.toUpperCase();
    switch (upper) {
      case 'FRA':
        return [const Color(0xFF002395), const Color(0xFFFFFFFF), const Color(0xFFED2939)];
      case 'COL':
        return [const Color(0xFFFCD116), const Color(0xFF003893), const Color(0xFFCE1126)];
      case 'USA':
        return [const Color(0xFF3C3B6E), const Color(0xFFFFFFFF), const Color(0xFFB22234)];
      case 'MEX':
        return [const Color(0xFF006847), const Color(0xFFFFFFFF), const Color(0xFFCE1126)];
      case 'CAN':
        return [const Color(0xFFFF0000), const Color(0xFFFFFFFF)];
      case 'CRI':
        return [const Color(0xFF002B7F), const Color(0xFFFFFFFF), const Color(0xFFEF2B2D)];
      case 'ARG':
        return [const Color(0xFF75AADB), const Color(0xFFFFFFFF)];
      case 'BRA':
        return [const Color(0xFF009739), const Color(0xFFFFDF00), const Color(0xFF002776)];
      default:
        return [];
    }
  }
}
