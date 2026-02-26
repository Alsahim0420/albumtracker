import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:albumtracker/core/theme/app_colors.dart';

/// Card de estado de completado: barra de progreso y TOTAL / FOUND / MISSING.
class TeamCompletionCard extends StatelessWidget {
  const TeamCompletionCard({
    super.key,
    required this.total,
    required this.found,
    required this.missing,
  });

  final int total;
  final int found;
  final int missing;

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (found / total).clamp(0.0, 1.0) : 0.0;
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'teamDetailCompletionStatus'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: colors.primary.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(colors.onSurface),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(percent * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatChip(label: 'teamDetailTotal'.tr(), value: '$total'),
              Container(
                width: 1,
                height: 20,
                color: colors.onSurfaceVariant,
              ),
              _StatChip(label: 'teamDetailFound'.tr(), value: '$found'),
              Container(
                width: 1,
                height: 20,
                color: colors.outlineVariant,
              ),
              _StatChip(label: 'homeFilterMissing'.tr(), value: '$missing'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
