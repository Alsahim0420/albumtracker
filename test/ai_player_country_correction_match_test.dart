import 'package:albumtracker/features/home/domain/entities/ai_detected_sticker.dart';
import 'package:albumtracker/features/home/domain/services/ai_analysis_to_seed_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

AiDetectedSticker _player({
  required String playerName,
  required String countryCode,
  String? rawText,
}) {
  return AiDetectedSticker(
    stickerCode: null,
    countryCode: countryCode,
    number: null,
    type: 'player',
    playerName: playerName,
    teamName: null,
    rawText: rawText,
    confidence: 0.99,
  );
}

void main() {
  group('AiAnalysisToSeedMatcher player country correction', () {
    final matcher = AiAnalysisToSeedMatcher();

    test('Steven Moreira con countryCode de club (USA) corrige a CPV', () {
      final r = matcher.match([
        _player(
          playerName: 'Steven Moreira',
          countryCode: 'USA',
          rawText: 'COLUMBUS CREW (USA) STEVEN MOREIRA',
        ),
      ]);
      expect(r.matchedStickers, hasLength(1));
      expect(r.matchedStickers.single.teamId, 'CPV');
      expect(
        r.warnings.any((w) => w.contains('countryCode corregido por nombre')),
        isTrue,
      );
    });

    test('Godfried Roemeratoe con countryCode de club (NED) corrige a CUW', () {
      final r = matcher.match([
        _player(
          playerName: 'Godfried Roemeratoe',
          countryCode: 'NED',
          rawText: 'RKC WAALWIJK (NED) GODFRIED ROEMERATOE',
        ),
      ]);
      expect(r.matchedStickers, hasLength(1));
      expect(r.matchedStickers.single.teamId, 'CUW');
      expect(
        r.warnings.any((w) => w.contains('countryCode corregido por nombre')),
        isTrue,
      );
    });

    test('Dean Huijsen con countryCode correcto (ESP) sigue matcheando', () {
      final r = matcher.match([
        _player(
          playerName: 'DEAN HUIJSEN',
          countryCode: 'ESP',
          rawText: 'DEAN HUIJSEN',
        ),
      ]);
      expect(r.matchedStickers, hasLength(1));
      expect(r.matchedStickers.single.teamId, 'ESP');
    });

    test('Joško Gvardiol matchea también como Josko Gvardiol', () {
      final r = matcher.match([
        _player(
          playerName: 'JOSKO GVARDIOL',
          countryCode: 'CRO',
          rawText: 'JOSKO GVARDIOL',
        ),
      ]);
      expect(r.matchedStickers, hasLength(1));
      expect(r.matchedStickers.single.playerName, contains('Gvardiol'));
    });
  });
}
