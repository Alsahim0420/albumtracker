import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/use_cases/add_stickers_by_global_numbers_use_case.dart';
import '../../domain/use_cases/update_sticker_count_use_case.dart';
import 'album_event.dart';
import 'album_state.dart';

/// Bloc que centraliza las mutaciones de la colección del álbum.
class AlbumBloc extends Bloc<AlbumEvent, AlbumState> {
  AlbumBloc({
    UpdateStickerCountUseCase? updateStickerCountUseCase,
    AddStickersByGlobalNumbersUseCase? addStickersByGlobalNumbersUseCase,
  })  : _updateStickerCountUseCase =
            updateStickerCountUseCase ?? UpdateStickerCountUseCase(),
        _addStickersByGlobalNumbersUseCase = addStickersByGlobalNumbersUseCase ??
            AddStickersByGlobalNumbersUseCase(),
        super(const AlbumInitial()) {
    on<AlbumUpdateStickerCountRequested>(_onUpdateStickerCountRequested);
    on<AlbumBulkAddRequested>(_onBulkAddRequested);
  }

  final UpdateStickerCountUseCase _updateStickerCountUseCase;
  final AddStickersByGlobalNumbersUseCase _addStickersByGlobalNumbersUseCase;

  Future<void> _onUpdateStickerCountRequested(
    AlbumUpdateStickerCountRequested event,
    Emitter<AlbumState> emit,
  ) async {
    try {
      await _updateStickerCountUseCase.call(event.stickerId, event.count);
    } catch (e) {
      emit(AlbumLoadFailure(e.toString()));
    }
  }

  Future<void> _onBulkAddRequested(
    AlbumBulkAddRequested event,
    Emitter<AlbumState> emit,
  ) async {
    try {
      await _addStickersByGlobalNumbersUseCase.call(event.globalNumbers);
    } catch (e) {
      emit(AlbumLoadFailure(e.toString()));
    }
  }
}
