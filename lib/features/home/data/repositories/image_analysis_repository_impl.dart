import 'package:albumtracker/features/home/data/datasources/image_analysis_remote_datasource.dart';
import 'package:albumtracker/features/home/domain/entities/ai_image_analysis_result.dart';
import 'package:albumtracker/features/home/domain/repositories/image_analysis_repository.dart';

class ImageAnalysisRepositoryImpl implements ImageAnalysisRepository {
  ImageAnalysisRepositoryImpl({required ImageAnalysisRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final ImageAnalysisRemoteDataSource _remoteDataSource;

  @override
  Future<AiImageAnalysisResult> analyzeImage(String imagePath) {
    return _remoteDataSource.analyzeImage(imagePath);
  }
}
