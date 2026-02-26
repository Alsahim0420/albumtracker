import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/features/home/domain/entities/sticker_entity.dart';

class StickerMapper {
  static StickerEntity toEntity(StickerModel model) {
    return StickerEntity(
      id: model.id,
      code: model.code,
      playerName: model.playerName ?? '',
      teamId: model.teamId,
      globalNumber: model.globalNumber?.toString() ?? '',
    );
  }
}