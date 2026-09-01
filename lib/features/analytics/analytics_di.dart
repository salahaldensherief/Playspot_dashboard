import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/dashboard_remote_data_source.dart';
import 'data/repositories/dashboard_repository_impl.dart';
import 'domain/repositories/dashboard_repository.dart';
import 'domain/usecases/get_lounge_owner_stats_usecase.dart';
import 'presentation/dashboard_cubit.dart';
import 'presentation/cubit/lounge_stats_cubit.dart';

void initAnalyticsDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(sl<SupabaseClient>()),
  );

  // Repositories
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton<GetLoungeOwnerStatsUseCase>(
    () => GetLoungeOwnerStatsUseCase(sl()),
  );

  // Cubits
  sl.registerFactory<DashboardCubit>(
    () => DashboardCubit(sl()),
  );

  sl.registerFactory<LoungeStatsCubit>(
    () => LoungeStatsCubit(sl()),
  );
}
