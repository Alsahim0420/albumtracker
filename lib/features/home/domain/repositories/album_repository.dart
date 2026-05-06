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
  Future<Either<Failure, void>> applyStickerCounts(Map<String, int> counts);

  /// Suma las cantidades del mapa a la colección actual (import CSV modo sumar).
  Future<Either<Failure, void>> mergeStickerCounts(Map<String, int> counts);

  /// Sustituye la colección por solo las entradas del mapa (import CSV modo reemplazar).
  Future<Either<Failure, void>> replaceStickerCounts(Map<String, int> counts);
}
