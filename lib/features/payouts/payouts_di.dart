import 'package:get_it/get_it.dart';
import 'data/datasources/payout_remote_data_source.dart';
import 'data/repositories/payout_repository_impl.dart';
import 'domain/repositories/payout_repository.dart';

void initPayoutsDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<PayoutRemoteDataSource>(
    () => PayoutRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<PayoutRepository>(
    () => PayoutRepositoryImpl(sl()),
  );
}
