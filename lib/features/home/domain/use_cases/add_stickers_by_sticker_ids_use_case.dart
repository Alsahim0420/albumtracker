import 'package:albumtracker/core/error/failures.dart';
import 'package:albumtracker/core/usecase/usecase.dart';
import 'package:albumtracker/features/home/domain/repositories/album_repository.dart';
import 'package:dartz/dartz.dart';

class AddStickersByStickerIdsParams {
  AddStickersByStickerIdsParams({
    required this.stickerIds,
  });

  final Iterable<String> stickerIds;
}

class AddStickersByStickerIdsUseCase
    extends UseCase<void, AddStickersByStickerIdsParams> {
  final AlbumRepository repository;

  AddStickersByStickerIdsUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(AddStickersByStickerIdsParams params) {
    return repository.addStickersByStickerIds(params.stickerIds);
  }
}
