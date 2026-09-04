import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/analytics/data/datasources/dashboard_remote_data_source.dart';
import 'package:play_spot_dashboard/features/analytics/data/repositories/dashboard_repository_impl.dart';
import 'package:play_spot_dashboard/features/analytics/domain/repositories/dashboard_repository.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/get_lounge_owner_stats_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/watch_active_sessions_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/extend_session_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/add_extras_to_session_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/end_session_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/review_extension_request_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/domain/usecases/handle_client_request_action_usecase.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/lounge_stats_cubit.dart';

void initAnalyticsDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(sl<SupabaseClient>()),
  );

  // Repositories
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(sl<DashboardRemoteDataSource>()),
  );

  // Use Cases
  sl.registerLazySingleton<GetLoungeOwnerStatsUseCase>(
    () => GetLoungeOwnerStatsUseCase(sl<DashboardRepository>()),
  );
  sl.registerLazySingleton<WatchActiveSessionsUseCase>(
    () => WatchActiveSessionsUseCase(sl<DashboardRepository>()),
  );
  sl.registerLazySingleton<ExtendSessionUseCase>(
    () => ExtendSessionUseCase(sl<DashboardRepository>()),
  );
  sl.registerLazySingleton<AddExtrasToSessionUseCase>(
    () => AddExtrasToSessionUseCase(sl<DashboardRepository>()),
  );
  sl.registerLazySingleton<EndSessionUseCase>(
    () => EndSessionUseCase(sl<DashboardRepository>()),
  );
  sl.registerLazySingleton<ReviewExtensionRequestUseCase>(
    () => ReviewExtensionRequestUseCase(sl<DashboardRepository>()),
  );
  sl.registerLazySingleton<HandleClientRequestActionUseCase>(
    () => HandleClientRequestActionUseCase(sl<DashboardRepository>()),
  );

  // Cubits
  sl.registerFactory<DashboardCubit>(
    () => DashboardCubit(
      loungeRepository: sl(),
      watchActiveSessionsUseCase: sl<WatchActiveSessionsUseCase>(),
      extendSessionUseCase: sl<ExtendSessionUseCase>(),
      addExtrasToSessionUseCase: sl<AddExtrasToSessionUseCase>(),
      endSessionUseCase: sl<EndSessionUseCase>(),
      reviewExtensionRequestUseCase: sl<ReviewExtensionRequestUseCase>(),
      handleClientRequestActionUseCase: sl<HandleClientRequestActionUseCase>(),
    ),
  );

  sl.registerFactory<LoungeStatsCubit>(
    () => LoungeStatsCubit(sl<GetLoungeOwnerStatsUseCase>()),
  );
}
