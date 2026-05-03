import 'package:albumtracker/core/error/failures.dart';
import 'package:albumtracker/core/usecase/usecase.dart';
import 'package:albumtracker/features/home/domain/entities/ocr_sticker_detection.dart';
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
    var needsReview = 0;

    for (final imagePath in params.imagePaths) {
      try {
        final pipeline = await _coordinator.processImage(imagePath);
        final stickers = pipeline.matchedStickers;
        final ocr = pipeline.ocrDetection;

        if (ocr.type == OcrLogicalStickerType.special) {
          needsReview += 1;
          final specialMsg = pipeline.side == StickerScanImageSide.front
              ? 'scanResultSpecialFrontReview'
              : 'scanResultSpecialReview';
          items.add(
            SingleStickerScanResult(
              imagePath: imagePath,
              rawText: pipeline.rawText,
              normalizedText: pipeline.normalizedText,
              detectedIdentifier: null,
              matchedSticker: null,
              status: StickerScanStatus.needsManualReview,
              message: specialMsg,
              imageSide: pipeline.side,
              ocrDetection: ocr,
            ),
          );
          continue;
        }

        if (stickers.isEmpty) {
          notFound += 1;
          var msg = _emptyMessageForSide(pipeline.side);
          if (ocr.countryCode != null && ocr.stickerNumber == null) {
            msg = 'scanResultWeAreNoNumber';
          }
          items.add(
            SingleStickerScanResult(
              imagePath: imagePath,
              rawText: pipeline.rawText,
              normalizedText: pipeline.normalizedText,
              detectedIdentifier: pipeline.detectedHint,
              matchedSticker: null,
              status: StickerScanStatus.notFound,
              message: msg,
              imageSide: pipeline.side,
              ocrDetection: ocr,
            ),
          );
          continue;
        }

        if (!pipeline.canAutoAdd) {
          needsReview += stickers.length;
          for (final sticker in stickers) {
            items.add(
              SingleStickerScanResult(
                imagePath: imagePath,
                rawText: pipeline.rawText,
                normalizedText: pipeline.normalizedText,
                detectedIdentifier: sticker.code,
                matchedSticker: sticker,
                status: StickerScanStatus.needsManualReview,
                message: 'scanResultLowConfidence',
                imageSide: pipeline.side,
                ocrDetection: ocr,
              ),
            );
          }
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
                ocrDetection: ocr,
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
              ocrDetection: ocr,
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
            ocrDetection: null,
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
        needsManualReview: needsReview,
        items: items,
      ),
    );
  }

  String _emptyMessageForSide(StickerScanImageSide side) {
    switch (side) {
      case StickerScanImageSide.unknown:
        return 'scanResultSideUnknown';
      case StickerScanImageSide.front:
        return 'scanResultFrontNoMatch';
      case StickerScanImageSide.back:
        return 'scanResultBackNoMatch';
    }
  }
}

class ScanStickersFromImagesParams {
  const ScanStickersFromImagesParams({required this.imagePaths});

  final List<String> imagePaths;
}
