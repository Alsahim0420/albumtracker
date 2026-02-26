import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:albumtracker/features/home/presentation/models/group_team_item.dart';
import 'flag_placeholder.dart';

/// Fila de equipo: bandera, nombre, barra de progreso, contador y chevron/check.
class TeamRow extends StatelessWidget {
  const TeamRow({
    super.key,
    required this.team,
    this.onTap,
  });

  final TeamProgress team;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colors.outlineVariant, width: 1),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                height: 24,
                child: team.flagCode != null
                    ? FittedBox(
                        fit: BoxFit.contain,
                        child: FlagPlaceholder(code: team.flagCode!),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: colors.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface,
                          ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: team.percent,
                        backgroundColor: colors.primary.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          team.isComplete ? colors.primaryContainer : colors.primary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${team.collected}/${team.total}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              team.isComplete
                  ? Icon(Icons.check_circle, color: colors.primaryContainer, size: 22)
                  : Icon(Icons.chevron_right, color: colors.onSurfaceVariant, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
