import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/features/home/domain/services/ocr/fifa_2026_back_ocr_parser.dart';
import 'package:albumtracker/features/home/domain/services/ocr/player_name_ocr_fuzzy_match.dart';

/// Matching desde candidatos OCR y texto libre.
///
/// Reglas de producto:
/// - En **frente** no se debe añadir una lámina solo por un código FIFA de 3 letras
///   (p. ej. país del club entre paréntesis).
/// - Código **autoritativo** de lámina por equipo+número: solo `MAR 5`, `POR 20`
///   (tres letras + **espacio** + 1–2 dígitos de slot) presente en el texto normalizado,
///   y preferiblemente con contexto de pie FIFA 2026 en reverso.
class StickerMatcherService {
  static final List<String> _rejectedMatchLines = <String>[];

  /// Líneas tipo `GER-10 rejected: …` generadas en el último [resolve].
  static List<String> takeRejectedMatchLog() {
    final out = List<String>.from(_rejectedMatchLines);
    _rejectedMatchLines.clear();
    return out;
  }

  static void clearRejectedMatchLog() => _rejectedMatchLines.clear();

  /// Registra un rechazo para depuración (p. ej. falso positivo país de club).
  static void logRejectedMatch(String stickerId, String reason) {
    _rejectedMatchLines.add('$stickerId rejected: $reason');
  }

  /// Quita país de club entre paréntesis/corchetes (ASCII y Unicode).
  /// No es evidencia de selección nacional ni código de lámina.
  static String stripClubNationHintsForOcr(String text) {
    var u = text.toUpperCase();
    u = u.replaceAll(
      RegExp(r'(?:\(|\[|（)\s*([A-Z]{3})\s*(?:\)|\]|）)'),
      ' ',
    );
    u = u.replaceAll(RegExp(r'\(\s*([A-Z]{3})\s*\)'), ' ');
    return u;
  }

  /// @nodoc Preferir [stripClubNationHintsForOcr].
  static String stripParentheticalNationClubHints(String text) =>
      stripClubNationHintsForOcr(text);

  /// Patrón de impresión tipo reverso oficial: `POR 20`, `NED 18`.
  static bool hasStrictAlbumTeamSpaceNumber(
    String normalizedUpper,
    String teamCode,
    int slot,
  ) {
    if (slot < 1 || slot > 20) return false;
    final team = teamCode.toUpperCase();
    if (team.length != 3) return false;
    final n = slot.toString();
    return RegExp(
      r'\b' + RegExp.escape(team) + r'\s+' + n + r'\b',
    ).hasMatch(normalizedUpper.toUpperCase());
  }

  /// Si el candidato resolvió una lámina de equipo, exige ancla textual `XXX NN`
  /// (y opcionalmente pie FIFA) para contar el match.
  static bool stickerFromCandidateIsAlbumCodeAnchored({
    required StickerModel sticker,
    required String normalizedUpperText,
    bool requireFifaAlbumFooter = false,
  }) {
    final t = normalizedUpperText.toUpperCase();
    if (requireFifaAlbumFooter &&
        !Fifa2026BackOcrParser.isFifaWorldCup2026BackText(t)) {
      return false;
    }
    final parts = sticker.code.split(' ');
    final n = int.tryParse(parts.isNotEmpty ? parts.last : '');
    if (n == null || n < 1 || n > 20) return false;
    return hasStrictAlbumTeamSpaceNumber(t, sticker.teamId, n);
  }

  /// Solo tres letras FIFA sin slot (no es identificador de lámina).
  static bool isBareThreeLetterTeamToken(String candidate) {
    final n = WorldCup2026Seed.normalizeStickerIdentifier(candidate);
    return RegExp(r'^[A-Z]{3}$').hasMatch(n);
  }

  /// Nombre de jugador claramente presente en el OCR (substring exacto o fuzzy solo nombre).
  static bool playerHasExplicitNameEvidence(StickerModel p, String scrubbedRawOcr) {
    if (p.type != StickerType.player) return true;
    final strict = WorldCup2026Seed.findStickersByPlayerNamesInText(scrubbedRawOcr);
    if (strict.any((x) => x.id == p.id)) return true;
    final blob = WorldCup2026Seed.normalizeTextForPlayerNameMatch(scrubbedRawOcr);
    final name = WorldCup2026Seed.normalizeTextForPlayerNameMatch(p.playerName ?? '');
    if (name.length < 6) return false;
    if (blob.contains(name)) return true;
    return PlayerNameOcrFuzzy.playerNameMatchesBlobEvidence(p, blob);
  }

  /// Texto original contenía país de club entre paréntesis (p. ej. `(GER)`).
  static bool rawHadParentheticalClubCountry(String rawOcrUpper, String fifaTeamCode) {
    final team = fifaTeamCode.toUpperCase();
    if (team.length != 3) return false;
    return RegExp(
      r'(?:\(|\[|（)\s*' + RegExp.escape(team) + r'\s*(?:\)|\]|）)',
    ).hasMatch(rawOcrUpper.toUpperCase());
  }

  static String buildPlayerRejectReason({
    required StickerModel sticker,
    required bool hadClubCountryParen,
    required bool hadNameEvidence,
    required bool hadAuthoritativeBackCode,
  }) {
    final parts = <String>[];
    if (hadClubCountryParen) {
      parts.add('team code came from club country hint "(${sticker.teamId})"');
    }
    if (!hadNameEvidence) {
      final n = sticker.playerName ?? '';
      parts.add('no player name "$n"');
    }
    if (!hadAuthoritativeBackCode) {
      final slot = int.tryParse(sticker.code.split(' ').last) ?? 0;
      parts.add('no authoritative back code "${sticker.teamId} $slot"');
    }
    return parts.join(' / ');
  }

  StickerModel? findBestMatch(
    List<String> candidates, {
    String? normalizedUpperText,
    bool requireAuthoritativeAlbumCodeInText = false,
    bool requireFifaFooterForAlbumCodes = false,
    bool ignoreCodifiedCandidates = false,
  }) {
    if (ignoreCodifiedCandidates) return null;
    for (final candidate in candidates) {
      if (isBareThreeLetterTeamToken(candidate)) continue;
      final sticker = WorldCup2026Seed.getStickerByFlexibleIdentifier(
        candidate,
      );
      if (sticker == null) continue;
      if (requireAuthoritativeAlbumCodeInText &&
          normalizedUpperText != null &&
          normalizedUpperText.isNotEmpty) {
        if (!stickerFromCandidateIsAlbumCodeAnchored(
          sticker: sticker,
          normalizedUpperText: normalizedUpperText,
          requireFifaAlbumFooter: requireFifaFooterForAlbumCodes,
        )) {
          continue;
        }
      }
      return sticker;
    }
    return null;
  }

  /// [preferPlayerNamesOnly]: no usar [candidates] para resolver láminas (solo nombres).
  ///
  /// [requireAuthoritativeAlbumCodeInText]: cada match por candidato debe incluir
  /// `TEAM  n` literal en [normalizedUpperText].
  List<StickerModel> findAllDistinctMatches(
    List<String> candidates, {
    String? rawOcrText,
    String? normalizedUpperText,
    bool preferPlayerNamesOnly = false,
    bool requireAuthoritativeAlbumCodeInText = false,
    bool requireFifaFooterForAlbumCodes = false,
  }) {
    final byId = <String, StickerModel>{};

    if (!preferPlayerNamesOnly) {
      for (final candidate in candidates) {
        if (isBareThreeLetterTeamToken(candidate)) continue;
        final sticker = WorldCup2026Seed.getStickerByFlexibleIdentifier(
          candidate,
        );
        if (sticker == null) continue;
        if (requireAuthoritativeAlbumCodeInText &&
            normalizedUpperText != null &&
            normalizedUpperText.isNotEmpty) {
          if (!StickerMatcherService.stickerFromCandidateIsAlbumCodeAnchored(
            sticker: sticker,
            normalizedUpperText: normalizedUpperText,
            requireFifaAlbumFooter: requireFifaFooterForAlbumCodes,
          )) {
            continue;
          }
        }
        byId[sticker.id] = sticker;
      }
    }

    if (rawOcrText != null && rawOcrText.isNotEmpty) {
      for (final sticker in PlayerNameOcrFuzzy.findPlayerStickersForOcrBlob(
        rawOcrText,
      )) {
        byId[sticker.id] = sticker;
      }
    }
    return byId.values.toList(growable: false);
  }
}
