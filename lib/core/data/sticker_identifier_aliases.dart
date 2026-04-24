/// Alias opcionales: códigos de reverso de láminas de otras ediciones (p. ej. Qatar 2022
/// con letra+número en esquina) → [StickerModel.id] del álbum cargado en la app.
///
/// Rellena solo entradas verificadas; las claves deben coincidir con lo que devuelve
/// [WorldCup2026Seed.normalizeStickerIdentifier] (ej. `C1`, `F12`).
const Map<String, String> kStickerIdentifierAliases = <String, String>{
  // Ejemplo: 'C1': 'MEX-B-01',
};
