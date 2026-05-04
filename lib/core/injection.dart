import 'package:albumtracker/core/services/openai_service.dart';
import 'package:albumtracker/features/home/data/datasources/album_local_datasource.dart';
import 'package:albumtracker/features/home/data/datasources/album_local_datasource_impl.dart';
import 'package:albumtracker/features/home/data/repositories/album_repository_impl.dart';
import 'package:albumtracker/features/home/data/services/sticker_image_input_service.dart';
import 'package:albumtracker/features/home/data/services/sticker_ocr_service.dart';
import 'package:albumtracker/features/home/domain/services/back_sticker_code_parser.dart';
import 'package:albumtracker/features/home/domain/services/back_sticker_matcher.dart';
import 'package:albumtracker/features/home/domain/services/front_sticker_matcher.dart';
import 'package:albumtracker/features/home/domain/services/sticker_image_side_detector.dart';
import 'package:albumtracker/features/home/domain/services/sticker_matcher_service.dart';
import 'package:albumtracker/features/home/domain/services/ocr/shield_captured_image_matcher.dart';
import 'package:albumtracker/features/home/domain/services/sticker_ocr_resolver.dart';
import 'package:albumtracker/features/home/domain/services/sticker_scan_coordinator.dart';
import 'package:albumtracker/features/home/domain/services/sticker_text_parser.dart';
import 'package:albumtracker/features/home/domain/repositories/album_repository.dart';
import 'package:albumtracker/features/home/domain/use_cases/add_stickers_by_sticker_ids_use_case.dart';
import 'package:albumtracker/features/home/domain/use_cases/get_album_data_use_case.dart';
import 'package:albumtracker/features/home/domain/use_cases/scan_stickers_from_images_use_case.dart';
import 'package:albumtracker/features/home/domain/use_cases/update_sticker_count_use_case.dart';
import 'package:albumtracker/features/home/presentation/bloc/album_bloc.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton<AlbumLocalDatasource>(
    () => AlbumLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<AlbumRepository>(
    () => AlbumRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton(() => StickerImageInputService());
  sl.registerLazySingleton(() => OpenAIService());
  sl.registerLazySingleton(() => StickerOcrService());
  sl.registerLazySingleton(() => StickerTextParser());
  sl.registerLazySingleton(() => StickerMatcherService());
  sl.registerLazySingleton(() => BackStickerCodeParser());
  sl.registerLazySingleton(
    () => StickerImageSideDetector(backParser: sl()),
  );
  sl.registerLazySingleton(() => FrontStickerMatcher());
  sl.registerLazySingleton(() => BackStickerMatcher(parser: sl()));
  sl.registerLazySingleton(() => ShieldCapturedImageMatcher());
  sl.registerLazySingleton(
    () => StickerOcrResolver(
      textParser: sl(),
      sideDetector: sl(),
      frontMatcher: sl(),
      backMatcher: sl(),
      shieldMatcher: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => StickerScanCoordinator(
      ocrService: sl(),
      ocrResolver: sl(),
      openAiService: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetAlbumDataUseCase(repository: sl()));
  sl.registerLazySingleton(() => UpdateStickerCountUseCase(repository: sl()));
  sl.registerLazySingleton(
    () => AddStickersByStickerIdsUseCase(repository: sl()),
  );
  sl.registerLazySingleton(
    () => ScanStickersFromImagesUseCase(
      repository: sl(),
      coordinator: sl(),
    ),
  );

  sl.registerFactory(
    () => AlbumBloc(
      getAlbumDataUseCase: sl(),
      updateStickerCountUseCase: sl(),
      addStickersByStickerIdsUseCase: sl(),
      scanStickersFromImagesUseCase: sl(),
    ),
  );
}
