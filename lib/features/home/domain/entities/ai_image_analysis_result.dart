import 'package:albumtracker/features/home/domain/entities/ai_detected_sticker.dart';

class AiImageAnalysisResult {
  const AiImageAnalysisResult({
    required this.imageSide,
    required this.stickers,
    required this.warnings,
  });

  final String imageSide;
  final List<AiDetectedSticker> stickers;
  final List<String> warnings;
}
