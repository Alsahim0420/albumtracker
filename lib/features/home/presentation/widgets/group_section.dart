import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/group_team_item.dart';
import 'team_row.dart';

/// Sección de grupo: título, % complete y lista de equipos.
class GroupSection extends StatelessWidget {
  const GroupSection({
    super.key,
    required this.group,
    this.onTeamTap,
  });

  final GroupWithTeams group;
  final void Function(TeamProgress team)? onTeamTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                group.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${group.percentComplete}% ${AppConstants.homeComplete}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
            children: group.teams
                .map(
                  (team) => TeamRow(
                    team: team,
                    onTap: onTeamTap != null ? () => onTeamTap!(team) : null,
                  ),
                )
                .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
