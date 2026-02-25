import 'package:flutter/material.dart';

import 'package:albumtracker/core/constants/app_constants.dart';

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
    final colors = Theme.of(context).colorScheme;
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
            AppConstants.homeTotalCollection,
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
              backgroundColor: colors.primary.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(colors.primaryContainer),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(),
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
