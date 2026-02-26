import 'package:albumtracker/core/error/failures.dart';
import 'package:albumtracker/core/usecase/usecase.dart';
import 'package:albumtracker/features/home/domain/repositories/album_repository.dart';
import 'package:albumtracker/features/home/domain/use_cases/update_sticker_count_params.dart';
import 'package:dartz/dartz.dart';

class UpdateStickerCountUseCase extends UseCase<void, UpdateStickerCountParams> {
  final AlbumRepository repository;

  UpdateStickerCountUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(UpdateStickerCountParams params) {
    return repository.updateStickerCount(params.stickerId, params.count);
  }
}
