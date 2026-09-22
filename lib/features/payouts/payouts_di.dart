import 'package:get_it/get_it.dart';
import 'data/datasources/payout_remote_data_source.dart';
import 'data/repositories/payout_repository_impl.dart';
import 'domain/repositories/payout_repository.dart';
import 'domain/usecases/payout_usecases.dart';
import 'presentation/cubit/payout_cubit.dart';

void initPayoutsDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<PayoutRemoteDataSource>(
    () => PayoutRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<PayoutRepository>(
    () => PayoutRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetPendingPayoutsOverviewUseCase(sl()));
  sl.registerLazySingleton(() => GetAllPayoutsUseCase(sl()));
  sl.registerLazySingleton(() => CreatePayoutUseCase(sl()));
  sl.registerLazySingleton(() => ApprovePayoutUseCase(sl()));
  sl.registerLazySingleton(() => StartPayoutProcessingUseCase(sl()));
  sl.registerLazySingleton(() => CompletePayoutUseCase(sl()));
  sl.registerLazySingleton(() => MarkPayoutPaidUseCase(sl()));
  sl.registerLazySingleton(() => FailPayoutUseCase(sl()));
  sl.registerLazySingleton(() => CancelPayoutUseCase(sl()));
  sl.registerLazySingleton(() => ResolvePayoutReviewUseCase(sl()));
  sl.registerLazySingleton(() => GetPayoutDetailsUseCase(sl()));
  sl.registerLazySingleton(() => GetPayoutsByLoungeUseCase(sl()));

  // Cubits
  sl.registerFactory<PayoutCubit>(
    () => PayoutCubit(
      getPendingPayoutsOverviewUseCase: sl(),
      getAllPayoutsUseCase: sl(),
      createPayoutUseCase: sl(),
      approvePayoutUseCase: sl(),
      startPayoutProcessingUseCase: sl(),
      completePayoutUseCase: sl(),
      markPayoutPaidUseCase: sl(),
      failPayoutUseCase: sl(),
      cancelPayoutUseCase: sl(),
      resolvePayoutReviewUseCase: sl(),
      getPayoutDetailsUseCase: sl(),
      getPayoutsByLoungeUseCase: sl(),
    ),
  );
}
