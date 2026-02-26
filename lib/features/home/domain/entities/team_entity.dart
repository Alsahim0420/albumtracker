import 'package:albumtracker/features/home/domain/entities/sticker_entity.dart';

class TeamEntity {
  final String id;
  final String name;
  final String groupId;
  final String flagAssetPath;
  final List<StickerEntity> stickers;

  TeamEntity({
    required this.id,
    required this.name,
    required this.groupId,
    required this.flagAssetPath,
    required this.stickers,
  });
}