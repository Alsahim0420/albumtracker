import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/error/failures.dart';
import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/core/usecase/usecase.dart';
import 'package:albumtracker/features/home/domain/entities/sticker_scan_result.dart';
import 'package:albumtracker/features/home/domain/repositories/album_repository.dart';
import 'package:albumtracker/features/home/domain/services/sticker_scan_coordinator.dart';
import 'package:dartz/dartz.dart';

class ScanStickersFromImagesUseCase
    extends UseCase<BatchStickerScanResult, ScanStickersFromImagesParams> {
  ScanStickersFromImagesUseCase({
    required AlbumRepository repository,
    required StickerScanCoordinator coordinator,
  }) : _repository = repository,
       _coordinator = coordinator;

  final AlbumRepository _repository;
  final StickerScanCoordinator _coordinator;

  @override
  Future<Either<Failure, BatchStickerScanResult>> call(
    ScanStickersFromImagesParams params,
  ) async {
    final collectionEither = await _repository.getCollection();
    if (collectionEither.isLeft()) {
      return Left(collectionEither.swap().getOrElse(() => DatabaseFailure()));
    }

    var collection = Map<String, int>.from(
      collectionEither.getOrElse(() => {}),
    );
    final items = <SingleStickerScanResult>[];
    var added = 0;
    var alreadyOwned = 0;
    var notFound = 0;
    var failed = 0;
    var needsReview = 0;

    for (var i = 0; i < params.imagePaths.length; i++) {
      if (i > 0) {
        // Cede al event loop para que el ticker de la animación siga entre fotos del lote.
        await Future<void>.delayed(Duration.zero);
      }
      final imagePath = params.imagePaths[i];
      try {
        final pipeline = await _coordinator.processImage(imagePath);
        final stickers = pipeline.matchedStickers;
        final ocr = pipeline.ocrDetection;

        if (stickers.isEmpty) {
          return Left(
            RemoteAnalysisFailure(
              'No se detectaron láminas válidas para la imagen',
            ),
          );
        }

        // Modo permisivo: si el pipeline resolvió láminas válidas, se agregan
        // sin bloquear por umbral de confianza (frente o reverso).
        //
        // Cada entrada en [stickers] suma +1 en Hive aunque repita el mismo id:
        // la primera copia “completa” la lámina; con count > 1 aparece en Repetidas / swaps.
        final pending = <(StickerModel sticker, String sid)>[];
        for (final sticker in stickers) {
          final sid = WorldCup2026Seed.normalizeStickerIdentifier(sticker.id);
          if (sid.isEmpty) {
            failed += 1;
            items.add(
              SingleStickerScanResult(
                imagePath: imagePath,
                rawText: pipeline.rawText,
                normalizedText: pipeline.normalizedText,
                detectedIdentifier: sticker.code,
                matchedSticker: sticker,
                status: StickerScanStatus.error,
                message: 'Invalid sticker id',
                imageSide: pipeline.side,
                ocrDetection: ocr,
              ),
            );
            continue;
          }
          pending.add((sticker, sid));
        }

        if (pending.isNotEmpty) {
          final idsInOrder = pending.map((p) => p.$2).toList();
          final addEither = await _repository.addStickersByStickerIds(idsInOrder);
          if (addEither.isLeft()) {
            for (final p in pending) {
              failed += 1;
              items.add(
                SingleStickerScanResult(
                  imagePath: imagePath,
                  rawText: pipeline.rawText,
                  normalizedText: pipeline.normalizedText,
                  detectedIdentifier: p.$1.code,
                  matchedSticker: p.$1,
                  status: StickerScanStatus.error,
                  message: 'Failed to add sticker',
                  imageSide: pipeline.side,
                  ocrDetection: ocr,
                ),
              );
            }
          } else {
            final working = Map<String, int>.from(collection);
            for (final p in pending) {
              final sticker = p.$1;
              final sid = p.$2;
              final wasOwned = (working[sid] ?? 0) > 0;
              working[sid] = (working[sid] ?? 0) + 1;
              if (wasOwned) {
                alreadyOwned += 1;
              } else {
                added += 1;
              }
              items.add(
                SingleStickerScanResult(
                  imagePath: imagePath,
                  rawText: pipeline.rawText,
                  normalizedText: pipeline.normalizedText,
                  detectedIdentifier: sticker.code,
                  matchedSticker: sticker,
                  status: wasOwned
                      ? StickerScanStatus.alreadyExists
                      : StickerScanStatus.added,
                  message: wasOwned ? 'Sticker already owned' : 'Sticker added',
                  imageSide: pipeline.side,
                  ocrDetection: ocr,
                ),
              );
            }
            collection = working;
          }
        }

        final refreshed = await _repository.getCollection();
        refreshed.fold((_) {}, (m) => collection = Map<String, int>.from(m));
      } catch (_) {
        return Left(RemoteAnalysisFailure('Error al analizar imagen con backend'));
      }
    }

    return Right(
      BatchStickerScanResult(
        total: items.length,
        processedStickerCount: added + alreadyOwned,
        added: added,
        alreadyOwned: alreadyOwned,
        notFound: notFound,
        failed: failed,
        needsManualReview: needsReview,
        items: items,
      ),
    );
  }

}

class ScanStickersFromImagesParams {
  const ScanStickersFromImagesParams({required this.imagePaths});

  final List<String> imagePaths;
}
