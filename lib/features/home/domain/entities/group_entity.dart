import 'package:albumtracker/features/home/domain/entities/team_entity.dart';

class GroupEntity {
  final String id;
  final String name;
  final List<TeamEntity> teams;

  GroupEntity({
    required this.id,
    required this.name,
    required this.teams,
  });
}