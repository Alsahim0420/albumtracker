import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/use_cases/add_stickers_by_global_numbers_use_case.dart';
import '../../domain/use_cases/get_album_data_use_case.dart';
import '../../domain/use_cases/update_sticker_count_use_case.dart';
import '../../domain/use_cases/update_sticker_count_params.dart';
import '../../domain/use_cases/add_stickers_params.dart';
import 'package:albumtracker/core/usecase/no_params.dart';
import 'album_event.dart';
import 'album_state.dart';

/// Bloc: Vista → Bloc → UseCase → Repository. No conoce Hive ni Model.
class AlbumBloc extends Bloc<AlbumEvent, AlbumState> {
  AlbumBloc({
    required GetAlbumDataUseCase getAlbumDataUseCase,
    required UpdateStickerCountUseCase updateStickerCountUseCase,
    required AddStickersByGlobalNumbersUseCase addStickersByGlobalNumbersUseCase,
  })  : _getAlbumDataUseCase = getAlbumDataUseCase,
        _updateStickerCountUseCase = updateStickerCountUseCase,
        _addStickersByGlobalNumbersUseCase = addStickersByGlobalNumbersUseCase,
        super(const AlbumInitial()) {
    on<AlbumLoadRequested>(_onLoadRequested);
    on<AlbumUpdateStickerCountRequested>(_onUpdateStickerCountRequested);
    on<AlbumBulkAddRequested>(_onBulkAddRequested);
  }

  final GetAlbumDataUseCase _getAlbumDataUseCase;
  final UpdateStickerCountUseCase _updateStickerCountUseCase;
  final AddStickersByGlobalNumbersUseCase _addStickersByGlobalNumbersUseCase;

  Future<void> _onLoadRequested(
    AlbumLoadRequested event,
    Emitter<AlbumState> emit,
  ) async {
    emit(AlbumLoading(previous: state.albumData));
    final result = await _getAlbumDataUseCase(NoParams());
    result.fold(
      (failure) => emit(AlbumError(
        message: 'Error al cargar',
        previous: state.albumData,
      )),
      (data) => emit(AlbumLoaded(albumData: data)),
    );
  }

  Future<void> _onUpdateStickerCountRequested(
    AlbumUpdateStickerCountRequested event,
    Emitter<AlbumState> emit,
  ) async {
    emit(AlbumLoading(previous: state.albumData));
    final result = await _updateStickerCountUseCase(
      UpdateStickerCountParams(stickerId: event.stickerId, count: event.count),
    );
    result.fold(
      (failure) => emit(AlbumError(
        message: 'Error al actualizar',
        previous: state.albumData,
      )),
      (_) => add(AlbumLoadRequested()),
    );
  }

  Future<void> _onBulkAddRequested(
    AlbumBulkAddRequested event,
    Emitter<AlbumState> emit,
  ) async {
    emit(AlbumLoading(previous: state.albumData));
    final result = await _addStickersByGlobalNumbersUseCase(
      AddStickersParams(globalNumbers: event.globalNumbers),
    );
    result.fold(
      (failure) => emit(AlbumError(
        message: 'Error al añadir',
        previous: state.albumData,
      )),
      (_) => add(AlbumLoadRequested()),
    );
  }
}
