import 'package:get_it/get_it.dart';
import 'data/datasources/loyalty_remote_data_source.dart';
import 'data/repositories/loyalty_repository_impl.dart';
import 'domain/repositories/loyalty_repository.dart';
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

  // Cubits
  sl.registerFactory<LoyaltyCubit>(
    () => LoyaltyCubit(sl()),
  );
}
