import 'package:albumtracker/core/error/failures.dart';
import 'package:albumtracker/features/home/domain/repositories/album_repository.dart';
import 'package:albumtracker/features/home/data/datasources/album_local_datasource.dart';
import 'package:dartz/dartz.dart';

/// Implementación del repositorio (data). Usa datasource y devuelve Either.
class AlbumRepositoryImpl implements AlbumRepository {
  final AlbumLocalDatasource localDataSource;

  AlbumRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Map<String, int>>> getCollection() async {
    try {
      final map = await localDataSource.getCollection();
      return Right(map);
    } catch (_) {
      return Left(DatabaseFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateStickerCount(String id, int count) async {
    try {
      await localDataSource.saveStickerCount(id, count);
      return const Right(null);
    } catch (_) {
      return Left(DatabaseFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addStickersByGlobalNumbers(
    Iterable<int> globalNumbers,
  ) async {
    try {
      await localDataSource.addStickersByGlobalNumbers(globalNumbers);
      return const Right(null);
    } catch (_) {
      return Left(DatabaseFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addStickersByStickerIds(
    Iterable<String> stickerIds,
  ) async {
    try {
      await localDataSource.addStickersByStickerIds(stickerIds);
      return const Right(null);
    } catch (_) {
      return Left(DatabaseFailure());
    }
  }

  @override
  Future<Either<Failure, void>> applyStickerCounts(Map<String, int> counts) async {
    try {
      await localDataSource.applyStickerCounts(counts);
      return const Right(null);
    } catch (_) {
      return Left(DatabaseFailure());
    }
  }

  @override
  Future<Either<Failure, void>> mergeStickerCounts(Map<String, int> counts) async {
    try {
      await localDataSource.mergeStickerCounts(counts);
      return const Right(null);
    } catch (_) {
      return Left(DatabaseFailure());
    }
  }

  @override
  Future<Either<Failure, void>> replaceStickerCounts(Map<String, int> counts) async {
    try {
      await localDataSource.replaceStickerCounts(counts);
      return const Right(null);
    } catch (_) {
      return Left(DatabaseFailure());
    }
  }
}
