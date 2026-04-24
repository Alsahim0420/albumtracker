import 'package:albumtracker/core/storage/hive_storage.dart' as hive;
import 'package:albumtracker/features/home/data/datasources/album_local_datasource.dart';

/// Implementación del datasource local. Usa hive_storage (Hive); solo la capa data conoce Hive.
class AlbumLocalDataSourceImpl implements AlbumLocalDatasource {
  @override
  Future<Map<String, int>> getCollection() async {
    return Future.value(hive.collectedStickersMap);
  }

  @override
  Future<void> saveStickerCount(String stickerId, int count) async {
    await hive.setStickerCount(stickerId, count);
  }

  @override
  Future<void> addStickersByGlobalNumbers(Iterable<int> globalNumbers) async {
    await hive.addStickersByGlobalNumbers(globalNumbers);
  }

  @override
  Future<void> addStickersByStickerIds(Iterable<String> stickerIds) async {
    await hive.addStickersByStickerIds(stickerIds);
  }
}
