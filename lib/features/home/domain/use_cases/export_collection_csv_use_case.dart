import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'package:albumtracker/core/error/failures.dart';
import 'package:albumtracker/core/platform/export_csv_share.dart';
import 'package:albumtracker/core/usecase/usecase.dart';
import 'package:albumtracker/features/home/domain/repositories/album_repository.dart';
import 'package:albumtracker/features/home/domain/services/collection_human_csv_codec.dart';
import 'package:csv/csv.dart';
import 'package:dartz/dartz.dart';

/// [languageCode]: `es` → cabeceras en español; cualquier otro → inglés (p. ej. `en`).
class ExportCollectionCsvParams {
  const ExportCollectionCsvParams({
    this.languageCode = 'en',
    this.sharePositionOrigin,
  });

  final String languageCode;
  final Rect? sharePositionOrigin;
}

class ExportCollectionCsvUseCase
    extends UseCase<void, ExportCollectionCsvParams> {
  ExportCollectionCsvUseCase({required this.repository});

  final AlbumRepository repository;

  @override
  Future<Either<Failure, void>> call(ExportCollectionCsvParams params) async {
    final collectionResult = await repository.getCollection();
    return collectionResult.fold<
      Future<Either<Failure, void>>
    >((f) async => Left(f), (map) async {
      try {
        final rows = CollectionHumanCsvCodec.buildRows(
          map,
          languageCode: params.languageCode,
        );
        const converter = ListToCsvConverter(eol: '\r\n');
        final csvBody = converter.convert(rows);
        final csv = '${CollectionHumanCsvCodec.utf8Bom}$csvBody';
        final name =
            'album_tracker_collection_${DateTime.now().millisecondsSinceEpoch}.csv';
        await shareExportedCsv(
          csv,
          name,
          sharePositionOrigin: params.sharePositionOrigin,
        );
        return const Right(null);
      } catch (e, stackTrace) {
        debugPrint('[CSV_EXPORT_DEBUG] failed error=$e');
        debugPrintStack(
          label: '[CSV_EXPORT_DEBUG] stack',
          stackTrace: stackTrace,
        );
        return Left(CsvExportFailure('$e'));
      }
    });
  }
}
