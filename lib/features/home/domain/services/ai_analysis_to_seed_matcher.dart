import 'dart:math' as math;

import 'package:albumtracker/core/data/seed_team_badge_match_index.dart';
import 'package:albumtracker/core/data/team_english_name_index.dart';
import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/features/home/domain/entities/ai_detected_sticker.dart';

class AiSeedMatchResult {
  const AiSeedMatchResult({
    required this.matchedStickers,
    required this.warnings,
    required this.rawTexts,
    required this.primaryStickerCode,
  });

  final List<StickerModel> matchedStickers;
  final List<String> warnings;
  final List<String> rawTexts;
  final String? primaryStickerCode;
}

class AiAnalysisToSeedMatcher {
  static const double _minConfidenceToAutoAdd = 0.55;

  /// Similitud mínima (Levenshtein normalizado) para aceptar fuzzy jugador mismo equipo.
  static const double _fuzzyPlayerMinSimilarity = 0.82;
  static const double _fuzzyGlobalPlayerMinSimilarity = 0.92;

  /// Si el 2.º mejor está a menos de esta distancia del mejor, no hay ganador claro.
  static const double _fuzzyAmbiguityGap = 0.02;

  /// Palabras habituales en federaciones / eventos; no son discriminativas de país.
  static const Set<String> _badgeNoiseTokens = {
    'fifa',
    'world',
    'cup',
    'official',
    'host',
    'qatar',
    'federation',
    'federacion',
    'association',
    'asociacion',
    'football',
    'futbol',
    'soccer',
    'fa',
    'fff',
    'fcb',
    'rfef',
    'the',
    'of',
    'and',
    'for',
    'inc',
    'ltd',
    'royal',
    'international',
    'tournament',
    'championship',
  };

  /// Si tras quitar ruido solo queda esto (± año), no se infiere país.
  static const Set<String> _badgeGenericOnlyTokens = {
    'fifa',
    'world',
    'cup',
    'official',
    'host',
    'qatar',
    'tm',
    'sticker',
    'album',
    'panini',
  };

  AiSeedMatchResult match(List<AiDetectedSticker> detections) {
    final matched = <StickerModel>[];
    final warnings = <String>[];
    final rawTexts = <String>[];
    String? primaryCode;

    for (final d in detections) {
      if (d.rawText != null && d.rawText!.trim().isNotEmpty) {
        rawTexts.add(d.rawText!.trim());
      }
      if (d.confidence < _minConfidenceToAutoAdd) {
        warnings.add('Baja confianza ignorada: ${d.rawText ?? d.stickerCode ?? d.type}');
        continue;
      }

      final fromCode = _matchByStickerCode(d);
      if (fromCode != null) {
        matched.add(fromCode);
        primaryCode ??= d.stickerCode ?? fromCode.code;
        continue;
      }

      final normalizedType = d.type.trim().toLowerCase();
      StickerModel? fallback;
      switch (normalizedType) {
        case 'player':
          fallback = _matchPlayerByNameAndTeam(d, warnings);
          break;
        case 'badge':
          fallback = _matchBadgeByTeam(d, warnings);
          break;
        case 'team_photo':
          fallback = _matchTeamPhotoByTeam(d);
          break;
        case 'special':
          fallback = _matchSpecial(d);
          break;
        default:
          fallback =
              _matchPlayerByNameAndTeam(d, warnings) ?? _matchBadgeByTeam(d, warnings);
          break;
      }

      if (fallback != null) {
        matched.add(fallback);
      } else {
        warnings.add('Sin match en seed: ${d.rawText ?? d.stickerCode ?? d.type}');
      }
    }

    return AiSeedMatchResult(
      matchedStickers: matched,
      warnings: warnings,
      rawTexts: rawTexts,
      primaryStickerCode: primaryCode,
    );
  }

  StickerModel? _matchByStickerCode(AiDetectedSticker d) {
    final code = d.stickerCode?.trim();
    if (code == null || code.isEmpty) return null;
    return WorldCup2026Seed.getStickerByFlexibleIdentifier(code);
  }

  StickerModel? _matchPlayerByNameAndTeam(
    AiDetectedSticker d,
    List<String> warnings,
  ) {
    final teamCode = _resolvePlayerTeamCode(d);
    final playerNorm = _normalize(d.playerName);
    if (playerNorm.isEmpty) {
      warnings.add(
        'No encontrado playerName=${d.playerName ?? ''} countryCode=${d.countryCode ?? ''} '
        'rawText=${d.rawText ?? ''} motivo=player_name_vacio',
      );
      return null;
    }

    if (teamCode != null) {
      final teamPlayers = _seedPlayersForTeam(teamCode);

      for (final sticker in teamPlayers) {
        final nameNorm = _normalize(sticker.playerName);
        if (nameNorm == playerNorm) return sticker;
      }

      final scored = <({StickerModel sticker, double sim})>[];
      for (final sticker in teamPlayers) {
        final nameNorm = _normalize(sticker.playerName);
        if (nameNorm.isEmpty) continue;
        final sim = _playerNameFuzzySimilarity(playerNorm, nameNorm);
        if (sim >= _fuzzyPlayerMinSimilarity) {
          scored.add((sticker: sticker, sim: sim));
        }
      }
      final winner = _singleBestCandidate(scored, d, teamCode, warnings);
      if (winner != null) {
        return winner;
      }
    }

    // Fallback global: ignora countryCode de IA cuando es sospechoso.
    final allPlayers = WorldCup2026Seed.stickerById.values
        .where((s) => s.type == StickerType.player)
        .toList();

    for (final sticker in allPlayers) {
      final nameNorm = _normalize(sticker.playerName);
      if (nameNorm == playerNorm) {
        final iaCountry = (d.countryCode ?? '').trim().toUpperCase();
        if (iaCountry.isNotEmpty && iaCountry != sticker.teamId.toUpperCase()) {
          warnings.add(
            'countryCode corregido por nombre: IA=$iaCountry, seed=${sticker.teamId.toUpperCase()}, '
            'player=${sticker.playerName ?? d.playerName ?? ''}',
          );
        }
        return sticker;
      }
    }

    final globalScored = <({StickerModel sticker, double sim})>[];
    for (final sticker in allPlayers) {
      final nameNorm = _normalize(sticker.playerName);
      if (nameNorm.isEmpty) continue;
      final sim = _playerNameFuzzySimilarity(playerNorm, nameNorm);
      if (sim >= _fuzzyGlobalPlayerMinSimilarity) {
        globalScored.add((sticker: sticker, sim: sim));
      }
    }

    if (globalScored.isNotEmpty) {
      globalScored.sort((a, b) => b.sim.compareTo(a.sim));
      final best = globalScored.first;
      final close = globalScored
          .where((x) => best.sim - x.sim <= _fuzzyAmbiguityGap)
          .toList();
      final closeCountries = close.map((x) => x.sticker.teamId).toSet();
      if (closeCountries.length == 1) {
        final iaCountry = (d.countryCode ?? '').trim().toUpperCase();
        if (iaCountry.isNotEmpty && iaCountry != best.sticker.teamId.toUpperCase()) {
          warnings.add(
            'countryCode corregido por nombre: IA=$iaCountry, seed=${best.sticker.teamId.toUpperCase()}, '
            'player=${best.sticker.playerName ?? d.playerName ?? ''}',
          );
        }
        return best.sticker;
      }
      warnings.add(
        'No encontrado playerName=${d.playerName ?? ''} countryCode=${d.countryCode ?? ''} '
        'rawText=${d.rawText ?? ''} motivo=ambiguo_global_por_nombre',
      );
      return null;
    }

    warnings.add(
      'No encontrado playerName=${d.playerName ?? ''} countryCode=${d.countryCode ?? ''} '
      'rawText=${d.rawText ?? ''} motivo=sin_candidato_global',
    );
    return null;
  }

  StickerModel? _singleBestCandidate(
    List<({StickerModel sticker, double sim})> scored,
    AiDetectedSticker d,
    String teamCode,
    List<String> warnings,
  ) {
    if (scored.isEmpty) return null;
    scored.sort((a, b) => b.sim.compareTo(a.sim));
    final bestSim = scored.first.sim;
    final tiedTop = scored.where((x) => (bestSim - x.sim).abs() < 1e-9).length;
    if (tiedTop > 1) {
      warnings.add(
        'Nombre jugador ambiguo (${d.playerName}, $teamCode): empate en similitud; sin match automático.',
      );
      return null;
    }
    final ambiguousCluster = scored
        .where((x) => bestSim - x.sim <= _fuzzyAmbiguityGap)
        .length;
    if (ambiguousCluster > 1) {
      warnings.add(
        'Nombre jugador ambiguo (${d.playerName}, $teamCode): varios candidatos muy similares; sin match automático.',
      );
      return null;
    }
    return scored.first.sticker;
  }

  /// Combina similitud sobre el nombre completo y (si coincide el nº de tokens)
  /// la media por token; se usa el máximo para cubrir apellidos largos y errores en un solo token.
  double _playerNameFuzzySimilarity(String detectedNorm, String seedNorm) {
    final fullSim = _normalizedLevenshteinSimilarity(detectedNorm, seedNorm);
    final dt = detectedNorm.split(' ').where((t) => t.isNotEmpty).toList();
    final st = seedNorm.split(' ').where((t) => t.isNotEmpty).toList();
    if (dt.length != st.length || dt.isEmpty) {
      return fullSim;
    }
    var tokenSum = 0.0;
    for (var i = 0; i < dt.length; i++) {
      tokenSum += _normalizedLevenshteinSimilarity(dt[i], st[i]);
    }
    final tokenAvg = tokenSum / dt.length;
    return math.max(fullSim, tokenAvg);
  }

  /// 1 - lev(a,b) / max(|a|,|b|). Vacíos: 0 salvo ambos vacíos → 1.
  double _normalizedLevenshteinSimilarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1;
    if (a.isEmpty || b.isEmpty) return 0;
    final maxLen = math.max(a.length, b.length);
    final dist = _levenshteinDistance(a, b);
    return 1.0 - dist / maxLen;
  }

  int _levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var previous = List<int>.generate(b.length + 1, (j) => j);
    var current = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      current[0] = i;
      final ai = a.codeUnitAt(i - 1);
      for (var j = 1; j <= b.length; j++) {
        final cost = ai == b.codeUnitAt(j - 1) ? 0 : 1;
        current[j] = math.min(
          math.min(current[j - 1] + 1, previous[j] + 1),
          previous[j - 1] + cost,
        );
      }
      final tmp = previous;
      previous = current;
      current = tmp;
    }
    return previous[b.length];
  }

  StickerModel? _matchBadgeByTeam(AiDetectedSticker d, List<String> warnings) {
    final teamCode = _resolveTeamCode(d);
    if (teamCode != null) {
      return _badgeStickerForTeamCode(teamCode);
    }

    final combined = [
      if (d.teamName != null && d.teamName!.trim().isNotEmpty) d.teamName!.trim(),
      if (d.rawText != null && d.rawText!.trim().isNotEmpty) d.rawText!.trim(),
    ].join(' ');
    if (combined.isEmpty) return null;

    final norm = WorldCup2026Seed.normalizeTextForPlayerNameMatch(combined);
    final stripped = _stripBadgeNoiseTokens(norm);
    if (_isOnlyGenericBadgeHaystack(stripped)) {
      return null;
    }

    final haystackMatch = SeedTeamBadgeMatchIndex.matchNormalizedHaystack(stripped);
    if (haystackMatch.ambiguous) {
      warnings.add(
        'Escudo/país ambiguo en OCR (${d.rawText ?? d.teamName ?? ''}); sin match automático.',
      );
      return null;
    }
    if (haystackMatch.fifa != null) {
      return _badgeStickerForTeamCode(haystackMatch.fifa!);
    }

    final upperCombined = combined
        .toUpperCase()
        .trim()
        .replaceAll(RegExp(r'[^A-Z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (upperCombined.isNotEmpty) {
      final multi = TeamEnglishNameIndex.countryCodesInText(upperCombined);
      if (multi.length > 1) {
        warnings.add(
          'Varios países detectados en el OCR del escudo; sin match automático.',
        );
        return null;
      }
      final english = TeamEnglishNameIndex.teamCodeForEnglishCountryName(combined);
      if (english != null) {
        return _badgeStickerForTeamCode(english);
      }
    }

    return null;
  }

  StickerModel? _badgeStickerForTeamCode(String teamCode) {
    final tc = teamCode.trim().toUpperCase();
    for (final sticker in WorldCup2026Seed.stickerById.values) {
      if (sticker.teamId.toUpperCase() != tc) continue;
      if (sticker.type == StickerType.badge) return sticker;
    }
    return null;
  }

  String _stripBadgeNoiseTokens(String normalizedLowerWithSpaces) {
    final out = normalizedLowerWithSpaces
        .split(' ')
        .where((t) => t.isNotEmpty && !_badgeNoiseTokens.contains(t))
        .join(' ')
        .trim();
    return out;
  }

  bool _isOnlyGenericBadgeHaystack(String strippedLowerWithSpaces) {
    final tokens = strippedLowerWithSpaces
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return true;
    final yearLike = RegExp(r'^20\d{2}$');
    return tokens.every(
      (t) =>
          _badgeGenericOnlyTokens.contains(t) ||
          yearLike.hasMatch(t),
    );
  }

  StickerModel? _matchTeamPhotoByTeam(AiDetectedSticker d) {
    final teamCode = _resolveTeamCode(d);
    if (teamCode == null) return null;
    for (final sticker in WorldCup2026Seed.stickerById.values) {
      if (sticker.teamId.toUpperCase() != teamCode) continue;
      if (sticker.type == StickerType.team_photo) return sticker;
    }
    return null;
  }

  StickerModel? _matchSpecial(AiDetectedSticker d) {
    final code = _normalize(d.stickerCode);
    final raw = _normalize(d.rawText);
    for (final sticker in WorldCup2026Seed.specialStickers) {
      final c = _normalize(sticker.code);
      final id = _normalize(sticker.id);
      if (code.isNotEmpty && (c == code || id == code)) return sticker;
      if (raw.isNotEmpty && (raw.contains(c) || raw.contains(id))) return sticker;
    }
    return null;
  }

  String? _resolveTeamCode(AiDetectedSticker d) {
    final fromCountry = d.countryCode?.trim().toUpperCase();
    if (fromCountry != null && fromCountry.length == 3) return fromCountry;
    final teamName = d.teamName?.trim() ?? '';
    if (teamName.isEmpty) return null;
    return TeamEnglishNameIndex.teamCodeForEnglishCountryName(teamName);
  }

  String? _resolvePlayerTeamCode(AiDetectedSticker d) {
    final fromCountry = d.countryCode?.trim().toUpperCase();
    if (fromCountry == null || fromCountry.length != 3) return null;
    final existsInSeed = WorldCup2026Seed.stickerById.values.any(
      (s) => s.type == StickerType.player && s.teamId.toUpperCase() == fromCountry,
    );
    return existsInSeed ? fromCountry : null;
  }

  List<StickerModel> _seedPlayersForTeam(String teamCode) {
    return WorldCup2026Seed.stickerById.values
        .where(
          (s) =>
              s.type == StickerType.player &&
              s.teamId.toUpperCase() == teamCode,
        )
        .toList();
  }

  String _normalize(String? value) {
    if (value == null) return '';
    var text = value.trim().toLowerCase();
    const accents = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
      'ç': 'c',
    };
    accents.forEach((k, v) => text = text.replaceAll(k, v));
    text = text.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }
}
