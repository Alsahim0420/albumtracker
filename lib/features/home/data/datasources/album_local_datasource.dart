abstract class AlbumLocalDatasource {
  Future<void> saveStickerCount(String stickerId, int count);
  Future<void> addStickersByGlobalNumbers(Iterable<int> globalNumbers);
  Future<Map<String, int>> getCollection();
}