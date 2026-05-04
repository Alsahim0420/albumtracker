import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/data/team_english_name_index.dart';
import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/features/home/domain/entities/ocr_sticker_detection.dart';
import 'package:albumtracker/features/home/domain/entities/sticker_scan_image_side.dart';
import 'package:albumtracker/features/home/domain/services/back_sticker_matcher.dart';
import 'package:albumtracker/features/home/domain/services/front_sticker_matcher.dart';
import 'package:albumtracker/features/home/domain/services/ocr/fifa_2026_back_ocr_parser.dart';
import 'package:albumtracker/features/home/domain/services/ocr/shield_captured_image_matcher.dart';
import 'package:albumtracker/features/home/domain/services/ocr/special_sticker_ocr_heuristic.dart';
import 'package:albumtracker/features/home/domain/services/ocr/we_are_front_country_parser.dart';
import 'package:albumtracker/features/home/domain/services/sticker_image_side_detector.dart';
import 'package:albumtracker/features/home/domain/services/sticker_matcher_service.dart';
import 'package:albumtracker/features/home/domain/services/sticker_text_parser.dart';

/// No auto-añadir por debajo de este umbral.
const double kOcrMinConfidenceToAutoAdd = 0.85;

class StickerOcrFullResult {
  const StickerOcrFullResult({
    required this.inferredSide,
    required this.resolvedStickers,
    required this.primaryDetection,
  });

  final StickerScanImageSide inferredSide;
  final List<StickerModel> resolvedStickers;
  final OcrStickerDetection primaryDetection;

  bool get canAutoAdd =>
      resolvedStickers.isNotEmpty &&
      !primaryDetection.needsManualReview &&
      primaryDetection.confidence >= kOcrMinConfidenceToAutoAdd;
}

/// Prioridad: 1) reverso oficial + `POR 11`, 2) escudo, 3) WE ARE + match frente, 4) legacy, 5) special.
class StickerOcrResolver {
  StickerOcrResolver({
    required this.textParser,
    required this.sideDetector,
    required this.frontMatcher,
    required this.backMatcher,
    WeAreFrontCountryParser? weAreParser,
    this.shieldMatcher,
  }) : weAre = weAreParser ?? WeAreFrontCountryParser();

  final StickerTextParser textParser;
  final StickerImageSideDetector sideDetector;
  final FrontStickerMatcher frontMatcher;
  final BackStickerMatcher backMatcher;
  final WeAreFrontCountryParser weAre;
  final ShieldCapturedImageMatcher? shieldMatcher;

  Future<StickerOcrFullResult> resolve({
    required String imagePath,
    required String rawOcrText,
  }) async {
    StickerMatcherService.clearRejectedMatchLog();
    final normalized = textParser.normalizeRawText(rawOcrText);
    final hasFifa = Fifa2026BackOcrParser.isFifaWorldCup2026BackText(normalized);
    final scrubbedRaw = StickerMatcherService.stripClubNationHintsForOcr(rawOcrText);
    final rawUpper = rawOcrText.toUpperCase();
    final we = weAre.teamCodeFromNormalizedOcr(normalized);
    final hasOfficialHeader =
        normalized.contains('FIFA') &&
        normalized.contains('WORLD') &&
        normalized.contains('CUP') &&
        normalized.contains('2026');
    StickerScanImageSide side;
    if (Fifa2026BackOcrParser.isFifaWorldCup2026BackText(normalized)) {
      side = StickerScanImageSide.back;
    } else {
      side = sideDetector.detect(
        rawOcrText: rawOcrText,
        normalizedUpperText: normalized,
      );
    }

    final multiBack = _resolveAllFifa2026BackStickers(normalized);
    final fifaPath = _resolveFifa2026BackPath(normalized);
    final frontCollage = frontMatcher.matchAllWithCountryInText(
      rawOcrText,
      requireExplicitFullPlayerNameInBlob: hasFifa,
    );
    final frontBestCollage = hasFifa
        ? frontMatcher.matchSingleBestEffort(
            rawOcrText,
            requireExplicitFullPlayerNameInBlob: true,
          )
        : null;

    final hybridMulti = _tryFifaAndFrontCollage(
      hasFifa: hasFifa,
      backs: multiBack,
      frontCollage: frontCollage,
      frontBest: frontBestCollage,
      normalized: normalized,
      scrubbedRaw: scrubbedRaw,
      rawUpper: rawUpper,
      requireFrontMatches: true,
    );
    if (hybridMulti != null) {
      return hybridMulti;
    }

    if (multiBack.length >= 2) {
      final backsOnly = _tryFifaAndFrontCollage(
        hasFifa: hasFifa,
        backs: multiBack,
        frontCollage: frontCollage,
        frontBest: null,
        normalized: normalized,
        scrubbedRaw: scrubbedRaw,
        rawUpper: rawUpper,
        requireFrontMatches: false,
      );
      if (backsOnly != null) {
        return backsOnly;
      }
    }

    if (fifaPath != null) {
      final hybridSingle = _tryFifaAndFrontCollage(
        hasFifa: hasFifa,
        backs: [fifaPath.$1],
        frontCollage: frontCollage,
        frontBest: frontBestCollage,
        normalized: normalized,
        scrubbedRaw: scrubbedRaw,
        rawUpper: rawUpper,
        requireFrontMatches: true,
      );
      if (hybridSingle != null) {
        return hybridSingle;
      }
      return StickerOcrFullResult(
        inferredSide: StickerScanImageSide.back,
        resolvedStickers: [fifaPath.$1],
        primaryDetection: fifaPath.$2,
      );
    }

    if (we != null) {
      // En collages del frente puede haber varias láminas: jugadores + "WE ARE ...".
      // Construimos un set combinado para no quedarnos solo con una detección temprana.
      final byId = <String, StickerModel>{};
      final front = frontMatcher.matchAllWithCountryInText(
        rawOcrText,
        requireExplicitFullPlayerNameInBlob: hasFifa,
      );
      for (final s in front) {
        byId[s.id] = s;
      }

      final weCodes = <String>{we};
      for (final line in rawOcrText.split('\n')) {
        final normalizedLine = textParser.normalizeRawText(line);
        final code = weAre.teamCodeFromNormalizedOcr(normalizedLine);
        if (code != null) {
          weCodes.add(code);
        }
      }
      for (final code in weCodes) {
        final teamPhoto = _teamPhotoStickerByTeam(code);
        if (teamPhoto != null) {
          byId[teamPhoto.id] = teamPhoto;
        }
      }

      if (byId.isNotEmpty) {
        final resolved = byId.values.toList(growable: false)
          ..sort((a, b) {
            final ga = a.globalNumber ?? (1 << 30);
            final gb = b.globalNumber ?? (1 << 30);
            final c = ga.compareTo(gb);
            if (c != 0) return c;
            return a.id.compareTo(b.id);
          });
        final first = resolved.first;
        final firstNumber = int.tryParse(first.code.split(' ').last) ??
            first.localNumber ??
            1;
        final conf = resolved.length == 1 ? 0.88 : 0.86;
        return StickerOcrFullResult(
          inferredSide: StickerScanImageSide.front,
          resolvedStickers: resolved,
          primaryDetection: OcrStickerDetection(
            countryCode: first.teamId,
            stickerNumber: firstNumber,
            code: first.code,
            type: OcrStickerDetection.fromStickerModelType(first.type),
            confidence: conf,
            detectionSource: _frontMultiPlayerSource(resolved),
            needsManualReview: conf < kOcrMinConfidenceToAutoAdd,
          ),
        );
      }
    }

    // Si trae cabecera oficial 2026 en anverso de escudo, forzar mejor candidato.
    if (hasOfficialHeader && shieldMatcher != null) {
      final shAny = await shieldMatcher!.findBestCandidate(imagePath);
      if (shAny != null && shAny.similarity >= 0.10) {
        final s = _stickerByTeamSlot(shAny.teamFifaCode, 1);
        if (s != null) {
          return StickerOcrFullResult(
            inferredSide: StickerScanImageSide.front,
            resolvedStickers: [s],
            primaryDetection: OcrStickerDetection(
              countryCode: s.teamId,
              stickerNumber: 1,
              code: s.code,
              type: OcrLogicalStickerType.badge,
              confidence: 0.86,
              detectionSource: OcrDetectionSource.shieldMatch,
              needsManualReview: false,
            ),
          );
        }
      }
    }

    if (shieldMatcher != null) {
      final sh = await shieldMatcher!.findBestMatch(imagePath);
      if (sh != null) {
        final s = _stickerByTeamSlot(sh.teamFifaCode, 1);
        if (s != null) {
          final conf = (0.75 + 0.22 * sh.similarity).clamp(0.0, 0.96);
          return StickerOcrFullResult(
            inferredSide: side,
            resolvedStickers: [s],
            primaryDetection: OcrStickerDetection(
              countryCode: s.teamId,
              stickerNumber: 1,
              code: s.code,
              type: OcrLogicalStickerType.badge,
              confidence: conf,
              detectionSource: OcrDetectionSource.shieldMatch,
              needsManualReview: conf < kOcrMinConfidenceToAutoAdd,
            ),
          );
        }
      }
    }

    if (we != null) {
      final front = frontMatcher.matchAllWithCountryInText(
        rawOcrText,
        requireExplicitFullPlayerNameInBlob: hasFifa,
      );
      if (front.isNotEmpty) {
        var conf = 0.83;
        if (we == front.first.teamId) {
          conf = 0.88;
        }
        final first = front.first;
        final n = int.tryParse(first.code.split(' ').last) ?? 1;
        return StickerOcrFullResult(
          inferredSide: StickerScanImageSide.front,
          resolvedStickers: front,
          primaryDetection: OcrStickerDetection(
            countryCode: we,
            stickerNumber: n,
            code: first.code,
            type: OcrStickerDetection.fromStickerModelType(first.type),
            confidence: conf,
            detectionSource: _frontMultiPlayerSource(front),
            needsManualReview: conf < kOcrMinConfidenceToAutoAdd,
          ),
        );
      }
    }

    if (side == StickerScanImageSide.back) {
      final b = backMatcher.matchSingle(normalized);
      if (b != null) {
        final conf = 0.78;
        return StickerOcrFullResult(
          inferredSide: StickerScanImageSide.back,
          resolvedStickers: [b],
          primaryDetection: OcrStickerDetection(
            countryCode: b.teamId,
            stickerNumber: int.tryParse(b.code.split(' ').last) ?? 1,
            code: b.code,
            type: OcrStickerDetection.fromStickerModelType(b.type),
            confidence: conf,
            detectionSource: OcrDetectionSource.legacyBack,
            needsManualReview: true,
          ),
        );
      }
    }

    if (side == StickerScanImageSide.front) {
      final f = frontMatcher.matchAllWithCountryInText(
        rawOcrText,
        requireExplicitFullPlayerNameInBlob: hasFifa,
      );
      if (f.isNotEmpty) {
        final t = f.first;
        final n = int.tryParse(t.code.split(' ').last) ?? 1;
        final isSingleMatch = f.length == 1;
        // Si el matcher devolvió candidatos válidos, permitimos auto-add también en lote.
        // Antes se dejaba en 0.72 para múltiples resultados y bloqueaba todo el auto-añadido.
        final conf = isSingleMatch ? 0.88 : 0.86;
        return StickerOcrFullResult(
          inferredSide: StickerScanImageSide.front,
          resolvedStickers: f,
          primaryDetection: OcrStickerDetection(
            countryCode: t.teamId,
            stickerNumber: n,
            code: t.code,
            type: OcrStickerDetection.fromStickerModelType(t.type),
            confidence: conf,
            detectionSource: _frontMultiPlayerSource(
              f,
              nonMultiAllPlayersSource: OcrDetectionSource.legacyFront,
            ),
            needsManualReview: conf < kOcrMinConfidenceToAutoAdd,
          ),
        );
      }
      final one = frontMatcher.matchSingleBestEffort(
        rawOcrText,
        requireExplicitFullPlayerNameInBlob: hasFifa,
      );
      if (one != null) {
        final n = int.tryParse(one.code.split(' ').last) ?? 1;
        const conf = 0.86;
        return StickerOcrFullResult(
          inferredSide: StickerScanImageSide.front,
          resolvedStickers: [one],
          primaryDetection: OcrStickerDetection(
            countryCode: one.teamId,
            stickerNumber: n,
            code: one.code,
            type: OcrStickerDetection.fromStickerModelType(one.type),
            confidence: conf,
            detectionSource: OcrDetectionSource.legacyFront,
            needsManualReview: false,
          ),
        );
      }

      // Fallback de escudo por país solo para OCR corto de UNA lámina.
      final countryMentions = TeamEnglishNameIndex.countryCodesInText(normalized);
      final countryFromText = weAre.teamCodeFromAnyCountryText(normalized);
      final looksSingleStickerText = normalized.length <= 170;
      if (countryFromText != null &&
          countryMentions.length == 1 &&
          looksSingleStickerText) {
        final badgeByText = _stickerByTeamSlot(countryFromText, 1);
        if (badgeByText != null) {
          return StickerOcrFullResult(
            inferredSide: StickerScanImageSide.front,
            resolvedStickers: [badgeByText],
            primaryDetection: OcrStickerDetection(
              countryCode: countryFromText,
              stickerNumber: 1,
              code: badgeByText.code,
              type: OcrLogicalStickerType.badge,
              confidence: 0.87,
              detectionSource: OcrDetectionSource.frontText,
              needsManualReview: false,
            ),
          );
        }
      }
    }

    if (we != null) {
      return StickerOcrFullResult(
        inferredSide: StickerScanImageSide.front,
        resolvedStickers: const [],
        primaryDetection: OcrStickerDetection(
          countryCode: we,
          confidence: 0.5,
          detectionSource: OcrDetectionSource.frontText,
          needsManualReview: true,
        ),
      );
    }

    if (SpecialStickerOcrHeuristic.looksLikeSpecialUnnumberedAlbumSticker(
      normalized,
    )) {
      return StickerOcrFullResult(
        inferredSide: side,
        resolvedStickers: const [],
        primaryDetection: OcrStickerDetection(
          type: OcrLogicalStickerType.special,
          confidence: 0.45,
          detectionSource: OcrDetectionSource.specialDetection,
          needsManualReview: true,
        ),
      );
    }

    return StickerOcrFullResult(
      inferredSide: side,
      resolvedStickers: const [],
      primaryDetection: OcrStickerDetection(
        type: OcrLogicalStickerType.unknown,
        confidence: 0.0,
        detectionSource: OcrDetectionSource.manualReview,
        needsManualReview: true,
      ),
    );
  }

  /// Collage FIFA: reversos anclados + jugadores (exact/fuzzy). Si [requireFrontMatches]
  /// es false, solo reversos (p. ej. varias láminas de reverso sin nombres legibles).
  StickerOcrFullResult? _tryFifaAndFrontCollage({
    required bool hasFifa,
    required List<StickerModel> backs,
    required List<StickerModel> frontCollage,
    required StickerModel? frontBest,
    required String normalized,
    required String scrubbedRaw,
    required String rawUpper,
    required bool requireFrontMatches,
  }) {
    if (!hasFifa || backs.isEmpty) return null;
    if (requireFrontMatches && frontCollage.isEmpty) return null;

    final byId = <String, StickerModel>{};
    for (final s in backs) {
      byId[s.id] = s;
    }
    if (requireFrontMatches) {
      for (final s in frontCollage) {
        byId[s.id] = s;
      }
      if (frontBest != null) {
        byId[frontBest.id] = frontBest;
      }
    }

    var resolved = byId.values.toList(growable: false)
      ..sort((a, b) {
        final ga = a.globalNumber ?? (1 << 30);
        final gb = b.globalNumber ?? (1 << 30);
        final c = ga.compareTo(gb);
        if (c != 0) return c;
        return a.id.compareTo(b.id);
      });
    resolved = _applyFifaCollageEvidenceFilter(
      resolved,
      normalized,
      scrubbedRaw,
      rawUpper,
    );
    if (resolved.isEmpty) return null;
    final first = resolved.first;
    final firstNum =
        first.localNumber ?? int.tryParse(first.code.split(RegExp(r'\s+')).last) ?? 0;
    return StickerOcrFullResult(
      inferredSide: StickerScanImageSide.unknown,
      resolvedStickers: resolved,
      primaryDetection: OcrStickerDetection(
        countryCode: first.teamId,
        stickerNumber: firstNum,
        code: first.code,
        type: OcrStickerDetection.fromStickerModelType(first.type),
        confidence: requireFrontMatches ? 0.89 : 0.9,
        detectionSource: requireFrontMatches
            ? OcrDetectionSource.combined
            : OcrDetectionSource.backText,
        needsManualReview: false,
      ),
    );
  }

  /// Quita jugadores/escudos sin ancla FIFA fuerte en collages (p. ej. GER por club).
  List<StickerModel> _applyFifaCollageEvidenceFilter(
    List<StickerModel> resolved,
    String normalizedUpper,
    String scrubbedRaw,
    String rawUpper,
  ) {
    final anchoredPairs =
        Fifa2026BackOcrParser.extractFifaStyleCodesAnchoredNearCup2026(normalizedUpper);
    bool slotAnchored(String teamId, int slot) {
      final tid = teamId.toUpperCase();
      return anchoredPairs.any((p) => p.code == tid && p.number == slot);
    }

    final out = <StickerModel>[];
    for (final s in resolved) {
      final slot = int.tryParse(s.code.split(' ').last) ?? 0;
      final anchored = slotAnchored(s.teamId, slot);

      if (s.type == StickerType.player) {
        final nameOk =
            StickerMatcherService.playerHasExplicitNameEvidence(s, scrubbedRaw);
        if (nameOk || anchored) {
          out.add(s);
          continue;
        }
        final hadParen = StickerMatcherService.rawHadParentheticalClubCountry(
          rawUpper,
          s.teamId,
        );
        StickerMatcherService.logRejectedMatch(
          s.id,
          StickerMatcherService.buildPlayerRejectReason(
            sticker: s,
            hadClubCountryParen: hadParen,
            hadNameEvidence: nameOk,
            hadAuthoritativeBackCode: anchored,
          ),
        );
        continue;
      }

      if (s.type == StickerType.badge || s.type == StickerType.team_photo) {
        if (anchored) {
          out.add(s);
        }
        continue;
      }

      out.add(s);
    }
    return out;
  }

  (StickerModel, OcrStickerDetection)? _resolveFifa2026BackPath(
    String normalized,
  ) {
    if (Fifa2026BackOcrParser.isFifaWorldCup2026BackText(normalized)) {
      final head = Fifa2026BackOcrParser.pickCodeNearFifaFooter(normalized);
      if (head != null) {
        final s0 = _stickerByTeamSlot(head.code, head.number);
        if (s0 != null) {
          return (
            s0,
            OcrStickerDetection(
              countryCode: head.code,
              stickerNumber: head.number,
              code: s0.code,
              type: OcrStickerDetection.fromStickerModelType(s0.type),
              confidence: 0.93,
              detectionSource: OcrDetectionSource.backText,
              needsManualReview: false,
            ),
          );
        }
      }
      final anchoredPairs =
          Fifa2026BackOcrParser.extractFifaStyleCodesAnchoredNearCup2026(normalized);
      final scanPairs = anchoredPairs.isNotEmpty
          ? anchoredPairs
          : Fifa2026BackOcrParser.extractFifaStyleCodes(normalized);
      for (final p in scanPairs.reversed) {
        final s = _stickerByTeamSlot(p.code, p.number);
        if (s != null) {
          return (
            s,
            OcrStickerDetection(
              countryCode: p.code,
              stickerNumber: p.number,
              code: s.code,
              type: OcrStickerDetection.fromStickerModelType(s.type),
              confidence: 0.9,
              detectionSource: OcrDetectionSource.backText,
              needsManualReview: false,
            ),
          );
        }
      }
      return null;
    }
    return null;
  }

  List<StickerModel> _resolveAllFifa2026BackStickers(String normalized) {
    if (!Fifa2026BackOcrParser.isFifaWorldCup2026BackText(normalized)) {
      return const [];
    }
    final byId = <String, StickerModel>{};
    final pairs =
        Fifa2026BackOcrParser.extractFifaStyleCodesAnchoredNearCup2026(normalized);
    for (final p in pairs) {
      final s = _stickerByTeamSlot(p.code, p.number);
      if (s != null) {
        byId[s.id] = s;
      }
    }
    final out = byId.values.toList(growable: false)
      ..sort((a, b) {
        final ga = a.globalNumber ?? (1 << 30);
        final gb = b.globalNumber ?? (1 << 30);
        final c = ga.compareTo(gb);
        if (c != 0) return c;
        return a.id.compareTo(b.id);
      });
    return out;
  }

  StickerModel? _stickerByTeamSlot(String teamFifa, int teamSlot) {
    final id = '$teamFifa-${teamSlot.toString().padLeft(2, '0')}';
    return WorldCup2026Seed.getStickerById(id) ??
        WorldCup2026Seed.getStickerByFlexibleIdentifier('$teamFifa $teamSlot') ??
        WorldCup2026Seed.getStickerByFlexibleIdentifier(id);
  }

  StickerModel? _teamPhotoStickerByTeam(String teamFifa) {
    for (final s in WorldCup2026Seed.stickerById.values) {
      if (s.teamId == teamFifa && s.type == StickerType.team_photo) {
        return s;
      }
    }
    return _stickerByTeamSlot(teamFifa, 13);
  }

  /// Varios jugadores en frente → [OcrDetectionSource.playerMatch].
  OcrDetectionSource _frontMultiPlayerSource(
    List<StickerModel> resolved, {
    OcrDetectionSource nonMultiAllPlayersSource = OcrDetectionSource.frontText,
  }) {
    if (resolved.length <= 1) return nonMultiAllPlayersSource;
    final allPlayers = resolved.every((s) => s.type == StickerType.player);
    if (allPlayers) return OcrDetectionSource.playerMatch;
    return nonMultiAllPlayersSource;
  }
}
