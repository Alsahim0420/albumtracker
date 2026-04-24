import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/features/home/domain/entities/sticker_scan_image_side.dart';
import 'package:albumtracker/features/home/domain/services/back_sticker_code_parser.dart';

/// Decide FRONT vs BACK vs UNKNOWN.
///
/// Reglas (orden fijo):
/// 1. **Frente tiene prioridad**: si el OCR contiene uno o más nombres de jugador
///    reconocidos en el plantel ([WorldCup2026Seed.findStickersByPlayerNamesInText]),
///    la imagen es **FRONT**, aunque también haya fechas, años, números sueltos o
///    fragmentos tipo código (p. ej. `L87` leído en estadísticas) que disparen el
///    [BackStickerCodeParser].
/// 2. **Reverso solo sin nombres**: **BACK** si no hay ninguna señal de nombre y sí
///    hay al menos un código estructurado de reverso.
/// 3. **UNKNOWN** si no hay nombres reconocidos ni códigos estructurados.
class StickerImageSideDetector {
  StickerImageSideDetector({BackStickerCodeParser? backParser})
    : _backParser = backParser ?? BackStickerCodeParser();

  final BackStickerCodeParser _backParser;

  /// [normalizedUpperText] = salida de normalización tipo [StickerTextParser.normalizeRawText].
  StickerScanImageSide detect({
    required String rawOcrText,
    required String normalizedUpperText,
  }) {
    final nameHits = WorldCup2026Seed.findStickersByPlayerNamesInText(rawOcrText);
    if (nameHits.isNotEmpty) {
      return StickerScanImageSide.front;
    }

    final codes = _backParser.extractStructuredCodes(normalizedUpperText);
    if (codes.isNotEmpty) {
      return StickerScanImageSide.back;
    }

    return StickerScanImageSide.unknown;
  }
}
