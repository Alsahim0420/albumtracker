import 'package:albumtracker/core/error/failures.dart';
import 'package:albumtracker/core/usecase/usecase.dart';
import 'package:albumtracker/features/home/domain/repositories/album_repository.dart';
import 'package:albumtracker/features/home/domain/use_cases/add_stickers_params.dart';
import 'package:dartz/dartz.dart';

class AddStickersByGlobalNumbersUseCase extends UseCase<void, AddStickersParams> {
  final AlbumRepository repository;

  AddStickersByGlobalNumbersUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(AddStickersParams params) {
    return repository.addStickersByGlobalNumbers(params.globalNumbers);
  }
}
