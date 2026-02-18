import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/group_team_item.dart';
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
    return Material(
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.inputBorder, width: 1),
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
                          color: AppColors.inputBorder,
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
                      team.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: team.percent,
                        backgroundColor: AppColors.progressTrack,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          team.isComplete ? AppColors.swapGreen : AppColors.primary,
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
                  ? Icon(Icons.check_circle, color: AppColors.swapGreen, size: 22)
                  : const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
