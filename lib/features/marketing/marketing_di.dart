import 'package:get_it/get_it.dart';
import 'data/datasources/marketing_remote_data_source.dart';
import 'data/repositories/marketing_repository_impl.dart';
import 'domain/repositories/marketing_repository.dart';
import 'domain/usecases/marketing_usecases.dart';
import 'presentation/cubit/marketing_cubit.dart';

void initMarketingDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<MarketingRemoteDataSource>(
    () => MarketingRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<MarketingRepository>(
    () => MarketingRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetPromotionsUseCase(sl()));
  sl.registerLazySingleton(() => CreatePromotionUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePromotionUseCase(sl()));
  sl.registerLazySingleton(() => DeletePromotionUseCase(sl()));
  sl.registerLazySingleton(() => UploadPromoPosterUseCase(sl()));
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => GetNotificationsPageUseCase(sl()));
  sl.registerLazySingleton(() => SendNotificationUseCase(sl()));

  // Cubits
  sl.registerFactory<MarketingCubit>(
    () => MarketingCubit(
      getPromotionsUseCase: sl(),
      createPromotionUseCase: sl(),
      updatePromotionUseCase: sl(),
      deletePromotionUseCase: sl(),
      uploadPromoPosterUseCase: sl(),
      getNotificationsUseCase: sl(),
      getNotificationsPageUseCase: sl(),
      sendNotificationUseCase: sl(),
    ),
  );
}
