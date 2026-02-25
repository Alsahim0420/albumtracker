import 'package:albumtracker/core/models/team_model.dart';
import 'package:albumtracker/features/home/data/mappers/sticker_mapper.dart';
import 'package:albumtracker/features/home/domain/entities/team_entity.dart';

class TeamMapper {
  static TeamEntity toEntity(TeamModel model) {
    return TeamEntity(
      id: model.id,
      name: model.name,
      groupId: model.groupId,
      flagAssetPath: model.flagAssetPath,
      stickers: model.stickers.map((sticker) => StickerMapper.toEntity(sticker)).toList(),
    );
  }
}