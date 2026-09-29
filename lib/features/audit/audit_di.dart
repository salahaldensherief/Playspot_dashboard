import 'package:get_it/get_it.dart';
import 'data/datasources/audit_remote_datasource.dart';
import 'data/repositories/audit_repository_impl.dart';
import 'domain/repositories/audit_repository.dart';
import 'domain/usecases/export_audit_logs_csv_usecase.dart';
import 'domain/usecases/get_audit_logs_usecase.dart';
import 'domain/usecases/get_timeline_logs_usecase.dart';
import 'presentation/audit_cubit.dart';

void initAuditDI(GetIt sl) {
  // Remote Datasource
  sl.registerLazySingleton<AuditRemoteDataSource>(
    () => AuditRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<AuditRepository>(
    () => AuditRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAuditLogsUsecase(sl()));
  sl.registerLazySingleton(() => GetTimelineLogsUsecase(sl()));
  sl.registerLazySingleton(() => ExportAuditLogsCsvUsecase(sl()));

  // Cubit
  sl.registerFactory(
    () => AuditCubit(
      getAuditLogsUsecase: sl(),
      exportAuditLogsCsvUsecase: sl(),
    ),
  );
}
