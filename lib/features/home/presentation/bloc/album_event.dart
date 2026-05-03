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

/// Solicita añadir laminas por identificadores de sticker (bulk add).
final class AlbumBulkAddRequested extends AlbumEvent {
  const AlbumBulkAddRequested(this.stickerIds);

  final Iterable<String> stickerIds;

  @override
  List<Object?> get props => [stickerIds];
}

final class AlbumScanImagesRequested extends AlbumEvent {
  const AlbumScanImagesRequested(this.imagePaths);

  final List<String> imagePaths;

  @override
  List<Object?> get props => [imagePaths];
}

final class AlbumLoadRequested extends AlbumEvent {
  const AlbumLoadRequested();

  @override
  List<Object?> get props => [];
}
