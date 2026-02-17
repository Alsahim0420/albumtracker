import 'package:flutter/material.dart';

/// Placeholder de bandera por código (colores representativos).
class FlagPlaceholder extends StatelessWidget {
  const FlagPlaceholder({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
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

  static List<Color> _colorsForCode(String code) {
    switch (code.toUpperCase()) {
      case 'FRA':
        return [const Color(0xFF002395), const Color(0xFFFFFFFF), const Color(0xFFED2939)];
      case 'COL':
        return [const Color(0xFFFCD116), const Color(0xFF003893), const Color(0xFFCE1126)];
      default:
        return [];
    }
  }
}
