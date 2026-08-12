import 'package:get_it/get_it.dart';
import 'data/datasources/admin_management_remote_data_source.dart';
import 'data/repositories/admin_management_repository_impl.dart';
import 'domain/repositories/admin_management_repository.dart';
import 'domain/usecases/create_lounge_admin_usecase.dart';
import 'domain/usecases/get_admins_usecase.dart';
import 'presentation/cubit/admin_management_cubit.dart';

void initUsersDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<AdminManagementRemoteDataSource>(
    () => AdminManagementRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<AdminManagementRepository>(
    () => AdminManagementRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => CreateLoungeAdminUseCase(sl()));
  sl.registerLazySingleton(() => GetAdminsUseCase(sl()));

  // Cubits
  sl.registerFactory<AdminManagementCubit>(
    () => AdminManagementCubit(
      createLoungeAdminUseCase: sl(),
      getAdminsUseCase: sl(),
      repository: sl(),
    ),
  );
}
