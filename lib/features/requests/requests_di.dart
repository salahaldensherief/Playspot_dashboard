import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/requests_remote_data_source.dart';
import 'data/repositories/client_requests_repository_impl.dart';
import 'domain/repositories/client_requests_repository.dart';
import 'presentation/cubit/client_requests_cubit.dart';

void initRequestsDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<RequestsRemoteDataSource>(
    () => RequestsRemoteDataSourceImpl(sl<SupabaseClient>()),
  );

  // Repositories
  sl.registerLazySingleton<ClientRequestsRepository>(
    () => ClientRequestsRepositoryImpl(sl()),
  );

  // Cubits
  sl.registerFactory<ClientRequestsCubit>(
    () => ClientRequestsCubit(
      repository: sl(),
      audioService: sl(),
    ),
  );
}
