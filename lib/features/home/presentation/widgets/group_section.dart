import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:albumtracker/core/theme/app_colors.dart';
import 'package:albumtracker/features/home/presentation/models/group_team_item.dart';
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
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'groupWithLetter'.tr(args: [group.name.contains(' ') ? group.name.split(' ').last : group.name]),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${group.percentComplete}% ${'homeComplete'.tr()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
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
