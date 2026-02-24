import 'package:equatable/equatable.dart';

/// Estado del [AlbumBloc].
sealed class AlbumState extends Equatable {
  const AlbumState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial / inactivo.
final class AlbumInitial extends AlbumState {
  const AlbumInitial();
}

/// Error al ejecutar una mutación.
final class AlbumLoadFailure extends AlbumState {
  const AlbumLoadFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
