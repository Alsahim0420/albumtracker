import 'package:albumtracker/features/home/data/datasources/album_local_datasource.dart';
import 'package:albumtracker/features/home/data/datasources/album_local_datasource_impl.dart';
import 'package:albumtracker/features/home/data/repositories/album_repository_impl.dart';
import 'package:albumtracker/features/home/domain/repositories/album_repository.dart';
import 'package:albumtracker/features/home/domain/use_cases/add_stickers_by_global_numbers_use_case.dart';
import 'package:albumtracker/features/home/domain/use_cases/get_album_data_use_case.dart';
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


  sl.registerLazySingleton(() => GetAlbumDataUseCase(repository: sl()));
  sl.registerLazySingleton(() => UpdateStickerCountUseCase(repository: sl()));
  sl.registerLazySingleton(
    () => AddStickersByGlobalNumbersUseCase(repository: sl()),
  );


  sl.registerFactory(
    () => AlbumBloc(
      getAlbumDataUseCase: sl(),
      updateStickerCountUseCase: sl(),
      addStickersByGlobalNumbersUseCase: sl(),
    ),
  );
}
