import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';


/// Card de progreso: porcentaje, barra, contador y swaps disponibles.
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.percent,
    required this.collected,
    required this.total,
    required this.swapsAvailable,
  });

  final int percent;
  final int collected;
  final int total;
  final int swapsAvailable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$percent%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'homeCompleted'.tr(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: colors.onSurfaceVariant.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(colors.onSurfaceVariant),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.titleMedium,
                      children: [
                        TextSpan(text: '$collected'),
                        TextSpan(
                          text: ' / $total',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$swapsAvailable ${'homeSwapsAvailable'.tr()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.primaryContainer,
                          fontWeight: FontWeight.w600,
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
