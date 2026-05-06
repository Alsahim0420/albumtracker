import 'package:albumtracker/features/home/domain/entities/ai_detected_sticker.dart';
import 'package:albumtracker/features/home/domain/services/ai_analysis_to_seed_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

AiDetectedSticker _badge({
  String? teamName,
  String? rawText,
  String? countryCode,
}) {
  return AiDetectedSticker(
    stickerCode: null,
    countryCode: countryCode,
    number: 0,
    type: 'badge',
    playerName: null,
    teamName: teamName,
    rawText: rawText,
    confidence: 1,
  );
}

void main() {
  group('AiAnalysisToSeedMatcher badge OCR sin countryCode', () {
    final matcher = AiAnalysisToSeedMatcher();

    test('Colombia — federación y gentilicio', () {
      final r = matcher.match([
        _badge(rawText: 'Federación Colombiana de Fútbol'),
      ]);
      expect(r.matchedStickers, hasLength(1));
      expect(r.matchedStickers.single.teamId, 'COL');
    });

    test('Belgium — Royal Belgian FA', () {
      final r = matcher.match([
        _badge(rawText: 'Royal Belgian FA'),
      ]);
      expect(r.matchedStickers, hasLength(1));
      expect(r.matchedStickers.single.teamId, 'BEL');
    });

    test('Uruguay — país desde texto español del seed', () {
      final r = matcher.match([
        _badge(rawText: 'Asociación Uruguaya de Fútbol Uruguay'),
      ]);
      expect(r.matchedStickers, hasLength(1));
      expect(r.matchedStickers.single.teamId, 'URU');
    });

    test('Solo texto FIFA World Cup — no inventar país', () {
      final r = matcher.match([
        _badge(rawText: 'FIFA WORLD CUP 2026 OFFICIAL'),
      ]);
      expect(r.matchedStickers, isEmpty);
      expect(r.warnings.any((w) => w.contains('Sin match')), isTrue);
    });
  });
}
