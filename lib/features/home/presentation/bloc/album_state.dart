// ignore_for_file: use_super_parameters

import 'package:equatable/equatable.dart';
import 'package:albumtracker/features/home/domain/entities/sticker_scan_result.dart';

/// Estado base con datos compartidos (lista/albumData, loading, error). Equatable.
abstract class AlbumState extends Equatable {
  const AlbumState({
    this.albumData = const {},
    this.isLoading = false,
    this.errorMessage,
    this.scanResult,
  });

  final Map<String, int> albumData;
  final bool isLoading;
  final String? errorMessage;
  final BatchStickerScanResult? scanResult;

  @override
  List<Object?> get props => [albumData, isLoading, errorMessage, scanResult];
}

/// Estado inicial.
class AlbumInitial extends AlbumState {
  const AlbumInitial() : super();
}

/// Cargando; mantiene datos previos.
class AlbumLoading extends AlbumState {
  const AlbumLoading({required Map<String, int> previous})
    : super(albumData: previous, isLoading: true);
}

/// Datos cargados.
class AlbumLoaded extends AlbumState {
  const AlbumLoaded({required super.albumData, super.scanResult})
    : super(isLoading: false);
}

/// Error; mantiene datos previos.
class AlbumError extends AlbumState {
  const AlbumError({
    required String message,
    required Map<String, int> previous,
  }) : super(albumData: previous, errorMessage: message);
}

class AlbumScanCompleted extends AlbumState {
  const AlbumScanCompleted({
    required super.albumData,
    required BatchStickerScanResult result,
  }) : super(scanResult: result);
}
