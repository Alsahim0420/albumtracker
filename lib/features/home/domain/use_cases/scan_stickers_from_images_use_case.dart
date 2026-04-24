import 'package:albumtracker/core/error/failures.dart';
import 'package:albumtracker/core/usecase/usecase.dart';
import 'package:albumtracker/features/home/domain/entities/sticker_scan_image_side.dart';
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

    for (final imagePath in params.imagePaths) {
      try {
        final pipeline = await _coordinator.processImage(imagePath);
        final stickers = pipeline.matchedStickers;

        if (pipeline.side == StickerScanImageSide.unknown) {
          notFound += 1;
          items.add(
            SingleStickerScanResult(
              imagePath: imagePath,
              rawText: pipeline.rawText,
              normalizedText: pipeline.normalizedText,
              detectedIdentifier: null,
              matchedSticker: null,
              status: StickerScanStatus.notFound,
              message: 'scanResultSideUnknown',
              imageSide: StickerScanImageSide.unknown,
            ),
          );
          continue;
        }

        if (stickers.isEmpty) {
          notFound += 1;
          items.add(
            SingleStickerScanResult(
              imagePath: imagePath,
              rawText: pipeline.rawText,
              normalizedText: pipeline.normalizedText,
              detectedIdentifier: pipeline.detectedHint,
              matchedSticker: null,
              status: StickerScanStatus.notFound,
              message: pipeline.side == StickerScanImageSide.front
                  ? 'scanResultFrontNoMatch'
                  : 'scanResultBackNoMatch',
              imageSide: pipeline.side,
            ),
          );
          continue;
        }

        for (final sticker in stickers) {
          final wasOwned = (collection[sticker.id] ?? 0) > 0;
          final addEither = await _repository.addStickersByStickerIds([
            sticker.id,
          ]);
          if (addEither.isLeft()) {
            failed += 1;
            items.add(
              SingleStickerScanResult(
                imagePath: imagePath,
                rawText: pipeline.rawText,
                normalizedText: pipeline.normalizedText,
                detectedIdentifier: sticker.code,
                matchedSticker: sticker,
                status: StickerScanStatus.error,
                message: 'Failed to add sticker',
                imageSide: pipeline.side,
              ),
            );
            continue;
          }

          collection[sticker.id] = (collection[sticker.id] ?? 0) + 1;
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
            ),
          );
        }
      } catch (_) {
        failed += 1;
        items.add(
          SingleStickerScanResult(
            imagePath: imagePath,
            rawText: '',
            normalizedText: '',
            detectedIdentifier: null,
            matchedSticker: null,
            status: StickerScanStatus.ocrFailed,
            message: 'OCR failed',
            imageSide: null,
          ),
        );
      }
    }

    return Right(
      BatchStickerScanResult(
        total: items.length,
        added: added,
        alreadyOwned: alreadyOwned,
        notFound: notFound,
        failed: failed,
        items: items,
      ),
    );
  }
}

class ScanStickersFromImagesParams {
  const ScanStickersFromImagesParams({required this.imagePaths});

  final List<String> imagePaths;
}
