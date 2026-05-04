import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/features/home/domain/entities/sticker_scan_image_side.dart';
import 'package:albumtracker/features/home/domain/services/back_sticker_code_parser.dart';
import 'package:albumtracker/features/home/domain/services/ocr/fifa_2026_back_ocr_parser.dart';

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
/// 3. **Fallback frente por texto libre**: si no hay señales exactas, pero el OCR
///    parece listado de nombres (alto contenido alfabético), se considera **FRONT**
///    para que el matcher flexible intente resolver.
/// 4. **UNKNOWN** si no hay nada confiable.
class StickerImageSideDetector {
  StickerImageSideDetector({BackStickerCodeParser? backParser})
    : _backParser = backParser ?? BackStickerCodeParser();

  final BackStickerCodeParser _backParser;

  /// [normalizedUpperText] = salida de normalización tipo [StickerTextParser.normalizeRawText].
  StickerScanImageSide detect({
    required String rawOcrText,
    required String normalizedUpperText,
  }) {
    if (Fifa2026BackOcrParser.isFifaWorldCup2026BackText(normalizedUpperText)) {
      return StickerScanImageSide.back;
    }
    final nameHits = WorldCup2026Seed.findStickersByPlayerNamesInText(rawOcrText);
    if (nameHits.isNotEmpty) {
      return StickerScanImageSide.front;
    }

    final codes = _backParser.extractStructuredCodes(normalizedUpperText);
    if (_hasValidBackCode(codes, normalizedUpperText)) {
      return StickerScanImageSide.back;
    }

    if (_looksLikeFrontByFreeText(rawOcrText)) {
      return StickerScanImageSide.front;
    }

    return StickerScanImageSide.unknown;
  }

  bool _hasValidBackCode(List<String> codes, String normalizedUpperText) {
    final fifaContext =
        Fifa2026BackOcrParser.isFifaWorldCup2026BackText(normalizedUpperText);
    for (final code in codes) {
      final sticker = WorldCup2026Seed.getStickerByFlexibleIdentifier(code);
      if (sticker == null) continue;
      if (sticker.type == StickerType.special) continue;
      if (!fifaContext && _looksLikeThreeLetterTeamSlotCode(code)) {
        continue;
      }
      return true;
    }
    return false;
  }

  /// Códigos tipo `POR-20` / `MAR-05` derivados de `POR 20` en promo/club sin pie FIFA.
  bool _looksLikeThreeLetterTeamSlotCode(String code) {
    final n = WorldCup2026Seed.normalizeStickerIdentifier(code);
    if (RegExp(r'^[A-Z]{3}-PL-\d{2}$').hasMatch(n)) return true;
    if (RegExp(r'^[A-Z]{3}-\d{2}$').hasMatch(n)) return true;
    return false;
  }

  bool _looksLikeFrontByFreeText(String rawOcrText) {
    final normalized = WorldCup2026Seed.normalizeTextForPlayerNameMatch(
      rawOcrText,
    );
    if (normalized.isEmpty) return false;
    final words = normalized
        .split(' ')
        .where((w) => w.length >= 4)
        .toList(growable: false);
    if (words.length < 4) return false;

    final joinedLen = normalized.replaceAll(' ', '').length;
    if (joinedLen < 20) return false;

    return true;
  }
}
