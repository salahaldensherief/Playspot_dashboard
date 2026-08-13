import 'package:get_it/get_it.dart';
import 'data/datasources/marketing_remote_data_source.dart';
import 'data/repositories/marketing_repository_impl.dart';
import 'domain/repositories/marketing_repository.dart';
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

  // Cubits
  sl.registerFactory<MarketingCubit>(
    () => MarketingCubit(sl()),
  );
}
