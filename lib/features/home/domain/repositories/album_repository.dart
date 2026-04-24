import 'package:albumtracker/core/error/failures.dart';
import 'package:dartz/dartz.dart';

/// Contrato del repositorio (domain). Solo entidades/Failure; sin Hive ni Model.
abstract class AlbumRepository {
  Future<Either<Failure, Map<String, int>>> getCollection();
  Future<Either<Failure, void>> updateStickerCount(String id, int count);
  Future<Either<Failure, void>> addStickersByGlobalNumbers(
    Iterable<int> globalNumbers,
  );
  Future<Either<Failure, void>> addStickersByStickerIds(
    Iterable<String> stickerIds,
  );
}
