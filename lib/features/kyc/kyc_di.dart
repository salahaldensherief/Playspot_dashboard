import 'package:get_it/get_it.dart';
import 'data/datasources/kyc_remote_data_source.dart';
import 'data/repositories/kyc_repository_impl.dart';
import 'domain/repositories/kyc_repository.dart';
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

  // Cubits
  sl.registerFactory<KycCubit>(
    () => KycCubit(sl()),
  );
}
