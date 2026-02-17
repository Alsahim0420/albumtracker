import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Icono de la app en el splash: cuadrado azul con logo blanco (A / flecha).
class SplashAppIcon extends StatelessWidget {
  const SplashAppIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        size: const Size(80, 80),
        painter: _AppLogoPainter(),
      ),
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Triángulo / flecha hacia arriba (estilo avión de papel)
    final path = Path()
      ..moveTo(center.dx, center.dy - 16)
      ..lineTo(center.dx + 14, center.dy + 10)
      ..lineTo(center.dx - 14, center.dy + 10)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
