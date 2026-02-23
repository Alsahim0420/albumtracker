import 'package:albumtracker/core/repository/album_repository.dart';

/// Caso de uso: añadir pegatinas por números globales (bulk add).
class AddStickersByGlobalNumbersUseCase {
  AddStickersByGlobalNumbersUseCase();

  Future<void> call(Iterable<int> globalNumbers) async {
    await AlbumRepository.addStickersByGlobalNumbers(globalNumbers);
  }
}
