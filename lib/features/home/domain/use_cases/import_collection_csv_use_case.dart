import 'package:albumtracker/core/error/failures.dart';
import 'package:albumtracker/core/usecase/usecase.dart';
import 'package:albumtracker/features/home/domain/repositories/album_repository.dart';
import 'package:albumtracker/features/home/domain/services/collection_human_csv_codec.dart';
import 'package:dartz/dartz.dart';

/// Modo de importación cuando ya hay colección persistida.
enum CollectionCsvImportMode {
  /// Cantidad final = actual + CSV (filas con cantidad ≤ 0 se ignoran).
  merge,

  /// La colección pasa a ser exactamente la descrita por el CSV (> 0).
  replace,
}

class ImportCollectionCsvParams {
  ImportCollectionCsvParams(
    this.csvText, {
    required this.mode,
  });

  final String csvText;
  final CollectionCsvImportMode mode;
}

/// Importa CSV legible (cabeceras EN/ES amigables o snake_case histórico)
/// o formato legado (`stickerId,count`). Acepta BOM UTF-8 al inicio del archivo.
class ImportCollectionCsvUseCase
    extends UseCase<int, ImportCollectionCsvParams> {
  ImportCollectionCsvUseCase({required this.repository});

  final AlbumRepository repository;

  @override
  Future<Either<Failure, int>> call(ImportCollectionCsvParams params) async {
    try {
      final text = params.csvText
          .trimLeft()
          .replaceFirst(CollectionHumanCsvCodec.utf8Bom, '')
          .trimLeft();
      if (text.isEmpty) {
        return Left(CsvImportFailure());
      }

      final parsed = CollectionHumanCsvCodec.parse(text);

      if (parsed.format == CollectionCsvImportFormat.empty) {
        return Left(CsvImportFailure());
      }

      final updates = parsed.stickerCounts;
      if (updates.isEmpty) {
        return const Right(0);
      }

      final applied = switch (params.mode) {
        CollectionCsvImportMode.merge => await repository.mergeStickerCounts(updates),
        CollectionCsvImportMode.replace => await repository.replaceStickerCounts(updates),
      };
      return applied.fold(
        (f) => Left(f),
        (_) => Right(updates.length),
      );
    } catch (e) {
      return Left(CsvImportFailure('$e'));
    }
  }
}
