import 'package:albumtracker/core/data/team_english_name_index.dart';

/// Frente: "WE ARE PORTUGAL" → código de equipo.
class WeAreFrontCountryParser {
  String? teamCodeFromNormalizedOcr(String normalizedUpperText) {
    return TeamEnglishNameIndex.fromWeAreLine(normalizedUpperText);
  }

  /// Fallback para OCR de escudo/foto de equipo sin "WE ARE" limpio.
  String? teamCodeFromAnyCountryText(String normalizedUpperText) {
    return TeamEnglishNameIndex.teamCodeForEnglishCountryName(
      normalizedUpperText,
    );
  }
}
