import 'package:get_it/get_it.dart';
import 'data/datasources/kyc_remote_data_source.dart';
import 'data/repositories/kyc_repository_impl.dart';
import 'domain/repositories/kyc_repository.dart';
import 'domain/usecases/kyc_usecases.dart';
import 'presentation/cubit/kyc_cubit.dart';

void initKycDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<KycRemoteDataSource>(
    () => KycRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<KycRepository>(
    () => KycRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => SubmitKycUseCase(sl()));
  sl.registerLazySingleton(() => GetPendingKycReviewsUseCase(sl()));
  sl.registerLazySingleton(() => ReviewKycUseCase(sl()));

  // Cubits
  sl.registerFactory<KycCubit>(
    () => KycCubit(
      submitKycUseCase: sl(),
      getPendingKycReviewsUseCase: sl(),
      reviewKycUseCase: sl(),
    ),
  );
}
