import '../widgets/sticker_item.dart';

/// Modelo de un ítem de lamina dentro de una sección (solo presentación/mock).
class AlbumStickerItem {
  const AlbumStickerItem({
    required this.number,
    required this.state,
    this.swapCount = 0,
  });

  final int number;
  final StickerState state;
  final int swapCount;
}

/// Modelo de una sección del álbum (solo presentación/mock).
class AlbumSection {
  const AlbumSection({
    required this.title,
    required this.items,
    this.flagCode,
  });

  final String title;
  final List<AlbumStickerItem> items;
  /// Código opcional para mostrar bandera (ej. FRA, COL). Si null, se usa barra azul.
  final String? flagCode;
}
