import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Card de progreso total: "TOTAL COLLECTION", barra verde y contador.
class TotalCollectionCard extends StatelessWidget {
  const TotalCollectionCard({
    super.key,
    required this.collected,
    required this.total,
  });

  final int collected;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (collected / total).clamp(0.0, 1.0) : 0.0;
    final pctOutOf100 = percent * 100;
    final percentDisplay = (pctOutOf100 > 0 && pctOutOf100 < 1) || pctOutOf100 > 99
        ? pctOutOf100.toStringAsFixed(1)
        : pctOutOf100.round().toString();
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Track: surco más oscuro que el fondo del card para que se vea también en 0 %.
    final progressTrackColor = Color.alphaBlend(
      Colors.black.withValues(alpha: isDark ? 0.48 : 0.16),
      colors.primaryContainer,
    );
    // Relleno: primary realzado (no primaryContainer: antes coincidía con el card).
    final progressValueColor = Color.alphaBlend(
      Colors.white.withValues(alpha: isDark ? 0.34 : 0.26),
      colors.primary,
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'homeTotalCollection'.tr(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: progressTrackColor,
              valueColor: AlwaysStoppedAnimation<Color>(progressValueColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'homeTotalCollectionPercent'.tr(args: [percentDisplay]),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$collected',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colors.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '/$total',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
