// ignore_for_file: override_on_non_overriding_member

import 'package:albumtracker/core/repository/album_repository.dart';
import 'package:albumtracker/features/home/data/datasources/album_local_datasource.dart';

class AlbumRepositoryImpl implements AlbumRepository {

  final AlbumLocalDatasource localDataSource;

  AlbumRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Map<String, int>> getCollection() async {
    return localDataSource.getCollection();
  }

  @override
  Future<void> saveStickerCount(
      String stickerId,
      int count,
  ) async {
    localDataSource.saveStickerCount(stickerId, count);
  }

  @override
  Future<int> addStickersByGlobalNumbers(
      Iterable<int> globalNumbers,
  ) async {
    await localDataSource.addStickersByGlobalNumbers(globalNumbers);
    return globalNumbers.length;
  }

}