import 'package:equatable/equatable.dart';

/// Eventos del [AlbumBloc].
sealed class AlbumEvent extends Equatable {
  const AlbumEvent();

  @override
  List<Object?> get props => [];
}

/// Solicita actualizar el conteo de una lamina.
final class AlbumUpdateStickerCountRequested extends AlbumEvent {
  const AlbumUpdateStickerCountRequested({
    required this.stickerId,
    required this.count,
  });

  final String stickerId;
  final int count;

  @override
  List<Object?> get props => [stickerId, count];
}

/// Solicita añadir laminas por números globales (bulk add).
final class AlbumBulkAddRequested extends AlbumEvent {
  const AlbumBulkAddRequested(this.globalNumbers);

  final Iterable<int> globalNumbers;

  @override
  List<Object?> get props => [globalNumbers];
}
final class AlbumLoadRequested extends AlbumEvent {
  const AlbumLoadRequested();

  @override
  List<Object?> get props => [];
}
