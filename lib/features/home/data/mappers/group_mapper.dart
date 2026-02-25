import 'package:albumtracker/core/models/group_model.dart';
import 'package:albumtracker/features/home/data/mappers/team_mapper.dart';
import 'package:albumtracker/features/home/domain/entities/group_entity.dart';

class GroupMapper {
  static GroupEntity toEntity(GroupModel model) {
    return GroupEntity(
      id: model.id,
      name: model.name,
      teams: model.teams.map((team) => TeamMapper.toEntity(team)).toList(),
    );
  }
}