import 'package:albumtracker/features/home/domain/entities/ai_image_analysis_result.dart';

abstract class ImageAnalysisRepository {
  Future<AiImageAnalysisResult> analyzeImage(String imagePath);
}
