import 'package:flutter/material.dart';

/// Icono de la app en el splash. Usa el asset del launcher.
class SplashAppIcon extends StatelessWidget {
  const SplashAppIcon({super.key});

  static const String _iconPath = 'assets/icon/app_icon.png';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        _iconPath,
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallback(context),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.sports_soccer,
        size: 64,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
