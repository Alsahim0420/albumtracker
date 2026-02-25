// ignore_for_file: use_super_parameters

import 'package:equatable/equatable.dart';

/// Estado base con datos compartidos (lista/albumData, loading, error). Equatable.
abstract class AlbumState extends Equatable {
  const AlbumState({
    this.albumData = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  final Map<String, int> albumData;
  final bool isLoading;
  final String? errorMessage;

  @override
  List<Object?> get props => [albumData, isLoading, errorMessage];
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
  const AlbumLoaded({required super.albumData}) : super(isLoading: false);
}

/// Error; mantiene datos previos.
class AlbumError extends AlbumState {
  const AlbumError({
    required String message,
    required Map<String, int> previous,
  }) : super(albumData: previous, errorMessage: message);
}
