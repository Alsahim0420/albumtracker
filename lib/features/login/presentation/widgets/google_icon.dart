import 'package:flutter/material.dart';

/// Icono "G" de Google (azul corporativo).
class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      'G',
      style: TextStyle(
        color: const Color(0xFF4285F4),
        fontSize: size,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
