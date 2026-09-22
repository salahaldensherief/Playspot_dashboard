import 'package:get_it/get_it.dart';
import 'data/datasources/loyalty_remote_data_source.dart';
import 'data/repositories/loyalty_repository_impl.dart';
import 'domain/repositories/loyalty_repository.dart';
import 'domain/usecases/loyalty_usecases.dart';
import 'presentation/cubit/loyalty_cubit.dart';

void initLoyaltyDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<LoyaltyRemoteDataSource>(
    () => LoyaltyRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<LoyaltyRepository>(
    () => LoyaltyRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetLoyaltyStatsUseCase(sl()));
  sl.registerLazySingleton(() => GetReferralsUseCase(sl()));
  sl.registerLazySingleton(() => GetLoyaltyTasksUseCase(sl()));
  sl.registerLazySingleton(() => UpdateLoyaltyTaskUseCase(sl()));
  sl.registerLazySingleton(() => GetLoyaltyLevelsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateLoyaltyLevelUseCase(sl()));
  sl.registerLazySingleton(() => AdjustUserPointsUseCase(sl()));
  sl.registerLazySingleton(() => GetPointsTransactionsPageUseCase(sl()));
  sl.registerLazySingleton(() => GetRedemptionOptionsUseCase(sl()));
  sl.registerLazySingleton(() => CreateRedemptionOptionUseCase(sl()));
  sl.registerLazySingleton(() => UpdateRedemptionOptionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteRedemptionOptionUseCase(sl()));

  // Cubits
  sl.registerFactory<LoyaltyCubit>(
    () => LoyaltyCubit(
      getLoyaltyStatsUseCase: sl(),
      getReferralsUseCase: sl(),
      getLoyaltyTasksUseCase: sl(),
      updateLoyaltyTaskUseCase: sl(),
      getLoyaltyLevelsUseCase: sl(),
      updateLoyaltyLevelUseCase: sl(),
      adjustUserPointsUseCase: sl(),
      getPointsTransactionsPageUseCase: sl(),
      getRedemptionOptionsUseCase: sl(),
      createRedemptionOptionUseCase: sl(),
      updateRedemptionOptionUseCase: sl(),
      deleteRedemptionOptionUseCase: sl(),
    ),
  );
}
