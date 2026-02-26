import 'package:albumtracker/core/error/failures.dart';
import 'package:albumtracker/core/usecase/no_params.dart';
import 'package:albumtracker/core/usecase/usecase.dart';
import 'package:albumtracker/features/home/domain/repositories/album_repository.dart';
import 'package:dartz/dartz.dart';

class GetAlbumDataUseCase extends UseCase<Map<String, int>, NoParams> {
  final AlbumRepository repository;

  GetAlbumDataUseCase({required this.repository});

  @override
  Future<Either<Failure, Map<String, int>>> call(NoParams params) {
    return repository.getCollection();
  }
}