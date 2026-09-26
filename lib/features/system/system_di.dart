import 'package:get_it/get_it.dart';
import 'data/datasources/system_remote_data_source.dart';
import 'data/repositories/system_repository_impl.dart';
import 'domain/repositories/system_repository.dart';
import 'domain/usecases/get_app_status_usecase.dart';
import 'domain/usecases/update_maintenance_mode_usecase.dart';
import 'domain/usecases/update_app_versions_usecase.dart';
import 'domain/usecases/get_announcements_usecase.dart';
import 'domain/usecases/create_announcement_usecase.dart';
import 'domain/usecases/deactivate_announcement_usecase.dart';
import 'presentation/system_settings_cubit.dart';
import 'presentation/cubit/app_status_cubit.dart';

void initSystemDI(GetIt sl) {
  // Data Source
  sl.registerLazySingleton<SystemRemoteDataSource>(
    () => SystemRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<SystemRepository>(
    () => SystemRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetAppStatusUseCase(sl()));
  sl.registerLazySingleton(() => UpdateMaintenanceModeUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAppVersionsUseCase(sl()));
  sl.registerLazySingleton(() => GetAnnouncementsUseCase(sl()));
  sl.registerLazySingleton(() => CreateAnnouncementUseCase(sl()));
  sl.registerLazySingleton(() => DeactivateAnnouncementUseCase(sl()));

  // Cubit
  sl.registerLazySingleton<AppStatusCubit>(
    () => AppStatusCubit(
      getAppStatusUseCase: sl(),
      supabaseClient: sl(),
    )..initAppStatusWatch(),
  );

  sl.registerFactory<SystemSettingsCubit>(
    () => SystemSettingsCubit(
      getAppStatusUseCase: sl(),
      updateMaintenanceModeUseCase: sl(),
      updateAppVersionsUseCase: sl(),
      getAnnouncementsUseCase: sl(),
      createAnnouncementUseCase: sl(),
      deactivateAnnouncementUseCase: sl(),
      loungeRepository: sl(),
    ),
  );
}
