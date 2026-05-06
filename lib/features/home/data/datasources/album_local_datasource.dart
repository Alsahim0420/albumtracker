abstract class AlbumLocalDatasource {
  Future<void> saveStickerCount(String stickerId, int count);
  Future<void> addStickersByGlobalNumbers(Iterable<int> globalNumbers);
  Future<void> addStickersByStickerIds(Iterable<String> stickerIds);
  Future<Map<String, int>> getCollection();
  Future<void> applyStickerCounts(Map<String, int> counts);
  Future<void> mergeStickerCounts(Map<String, int> counts);
  Future<void> replaceStickerCounts(Map<String, int> counts);
}
