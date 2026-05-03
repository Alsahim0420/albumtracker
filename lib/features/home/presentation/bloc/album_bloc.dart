import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/use_cases/add_stickers_by_sticker_ids_use_case.dart';
import '../../domain/use_cases/scan_stickers_from_images_use_case.dart';
import '../../domain/use_cases/get_album_data_use_case.dart';
import '../../domain/use_cases/update_sticker_count_use_case.dart';
import '../../domain/use_cases/update_sticker_count_params.dart';
import 'package:albumtracker/core/usecase/no_params.dart';
import 'album_event.dart';
import 'album_state.dart';

/// Bloc: Vista → Bloc → UseCase → Repository. No conoce Hive ni Model.
class AlbumBloc extends Bloc<AlbumEvent, AlbumState> {
  AlbumBloc({
    required GetAlbumDataUseCase getAlbumDataUseCase,
    required UpdateStickerCountUseCase updateStickerCountUseCase,
    required AddStickersByStickerIdsUseCase addStickersByStickerIdsUseCase,
    required ScanStickersFromImagesUseCase scanStickersFromImagesUseCase,
  }) : _getAlbumDataUseCase = getAlbumDataUseCase,
       _updateStickerCountUseCase = updateStickerCountUseCase,
       _addStickersByStickerIdsUseCase = addStickersByStickerIdsUseCase,
       _scanStickersFromImagesUseCase = scanStickersFromImagesUseCase,
       super(const AlbumInitial()) {
    on<AlbumLoadRequested>(_onLoadRequested);
    on<AlbumUpdateStickerCountRequested>(_onUpdateStickerCountRequested);
    on<AlbumBulkAddRequested>(_onBulkAddRequested);
    on<AlbumScanImagesRequested>(_onScanImagesRequested);
  }

  final GetAlbumDataUseCase _getAlbumDataUseCase;
  final UpdateStickerCountUseCase _updateStickerCountUseCase;
  final AddStickersByStickerIdsUseCase _addStickersByStickerIdsUseCase;
  final ScanStickersFromImagesUseCase _scanStickersFromImagesUseCase;

  Future<void> _onLoadRequested(
    AlbumLoadRequested event,
    Emitter<AlbumState> emit,
  ) async {
    emit(AlbumLoading(previous: state.albumData));
    final result = await _getAlbumDataUseCase(NoParams());
    result.fold(
      (failure) => emit(
        AlbumError(message: 'Error al cargar', previous: state.albumData),
      ),
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
      (failure) => emit(
        AlbumError(message: 'Error al actualizar', previous: state.albumData),
      ),
      (_) => add(AlbumLoadRequested()),
    );
  }

  Future<void> _onBulkAddRequested(
    AlbumBulkAddRequested event,
    Emitter<AlbumState> emit,
  ) async {
    emit(AlbumLoading(previous: state.albumData));
    final result = await _addStickersByStickerIdsUseCase(
      AddStickersByStickerIdsParams(stickerIds: event.stickerIds),
    );
    result.fold(
      (failure) => emit(
        AlbumError(message: 'Error al añadir', previous: state.albumData),
      ),
      (_) => add(AlbumLoadRequested()),
    );
  }

  Future<void> _onScanImagesRequested(
    AlbumScanImagesRequested event,
    Emitter<AlbumState> emit,
  ) async {
    emit(AlbumLoading(previous: state.albumData));
    final result = await _scanStickersFromImagesUseCase(
      ScanStickersFromImagesParams(imagePaths: event.imagePaths),
    );
    final albumDataResult = await _getAlbumDataUseCase(NoParams());
    final refreshedData = albumDataResult.getOrElse(() => state.albumData);

    result.fold(
      (failure) => emit(
        AlbumError(message: 'Error al escanear', previous: refreshedData),
      ),
      (scanResult) => emit(
        AlbumScanCompleted(albumData: refreshedData, result: scanResult),
      ),
    );
  }
}
