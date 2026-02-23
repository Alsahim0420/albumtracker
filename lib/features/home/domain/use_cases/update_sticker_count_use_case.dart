import 'package:albumtracker/core/repository/album_repository.dart';

/// Caso de uso: actualizar la cantidad de una pegatina en la colección.
class UpdateStickerCountUseCase {
  UpdateStickerCountUseCase();

  Future<void> call(String stickerId, int count) async {
    await AlbumRepository.updateStickerCount(stickerId, count);
  }
}
