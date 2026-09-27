import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/requests_remote_data_source.dart';
import 'data/datasources/requests_remote_data_source_impl.dart';
import 'data/repositories/client_requests_repository_impl.dart';
import 'domain/repositories/client_requests_repository.dart';
import 'domain/usecases/get_active_lounge_requests_page_usecase.dart';
import 'domain/usecases/mark_request_as_attended_usecase.dart';
import 'domain/usecases/watch_client_requests_usecase.dart';
import 'presentation/client_requests_cubit.dart';

void initRequestsDI(GetIt sl) {
  // Data Sources
  if (!sl.isRegistered<RequestsRemoteDataSource>()) {
    sl.registerLazySingleton<RequestsRemoteDataSource>(
      () => RequestsRemoteDataSourceImpl(sl<SupabaseClient>()),
    );
  }

  // Repositories
  if (!sl.isRegistered<ClientRequestsRepository>()) {
    sl.registerLazySingleton<ClientRequestsRepository>(
      () => ClientRequestsRepositoryImpl(sl()),
    );
  }

  // Use Cases
  if (!sl.isRegistered<WatchClientRequestsUseCase>()) {
    sl.registerLazySingleton(() => WatchClientRequestsUseCase(sl()));
  }
  if (!sl.isRegistered<MarkRequestAsAttendedUseCase>()) {
    sl.registerLazySingleton(() => MarkRequestAsAttendedUseCase(sl()));
  }
  if (!sl.isRegistered<GetActiveLoungeRequestsPageUseCase>()) {
    sl.registerLazySingleton(() => GetActiveLoungeRequestsPageUseCase(sl()));
  }

  // Cubits
  if (!sl.isRegistered<ClientRequestsCubit>()) {
    sl.registerLazySingleton<ClientRequestsCubit>(
      () => ClientRequestsCubit(
        watchClientRequestsUseCase: sl(),
        markRequestAsAttendedUseCase: sl(),
        getActiveLoungeRequestsPageUseCase: sl(),
        audioService: sl(),
      ),
    );
  }
}
