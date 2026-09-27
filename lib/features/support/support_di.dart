import 'package:get_it/get_it.dart';
import 'data/datasources/support_remote_data_source.dart';
import 'data/repositories/support_repository_impl.dart';
import 'domain/repositories/support_repository.dart';
import 'domain/usecases/get_app_settings_usecase.dart';
import 'domain/usecases/update_app_settings_usecase.dart';
import 'domain/usecases/get_policies_usecase.dart';
import 'domain/usecases/update_policy_usecase.dart';
import 'domain/usecases/get_faqs_usecase.dart';
import 'domain/usecases/save_faq_usecase.dart';
import 'domain/usecases/delete_faq_usecase.dart';
import 'domain/usecases/get_support_tickets_usecase.dart';
import 'domain/usecases/create_support_ticket_usecase.dart';
import 'domain/usecases/update_ticket_status_usecase.dart';
import 'presentation/support_cubit.dart';

void initSupportDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<SupportRemoteDataSource>(
    () => SupportRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<SupportRepository>(
    () => SupportRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetAppSettingsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAppSettingsUseCase(sl()));
  sl.registerLazySingleton(() => GetPoliciesUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePolicyUseCase(sl()));
  sl.registerLazySingleton(() => GetFaqsUseCase(sl()));
  sl.registerLazySingleton(() => SaveFaqUseCase(sl()));
  sl.registerLazySingleton(() => DeleteFaqUseCase(sl()));
  sl.registerLazySingleton(() => GetSupportTicketsUseCase(sl()));
  sl.registerLazySingleton(() => CreateSupportTicketUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTicketStatusUseCase(sl()));

  // Cubits
  sl.registerFactory<SupportCubit>(
    () => SupportCubit(
      getAppSettingsUseCase: sl(),
      updateAppSettingsUseCase: sl(),
      getPoliciesUseCase: sl(),
      updatePolicyUseCase: sl(),
      getFaqsUseCase: sl(),
      saveFaqUseCase: sl(),
      deleteFaqUseCase: sl(),
      getSupportTicketsUseCase: sl(),
      createSupportTicketUseCase: sl(),
      updateTicketStatusUseCase: sl(),
    ),
  );
}
