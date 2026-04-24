/// Cara de la lámina inferida a partir del OCR (estrategia de matching).
enum StickerScanImageSide {
  /// Frente: nombre de jugador + país.
  front,

  /// Reverso: solo códigos estructurados impresos.
  back,

  /// No se pudo clasificar con confianza: sin auto-añadir.
  unknown,
}
