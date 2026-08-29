import 'package:get_it/get_it.dart';
import 'data/data_sources/permissions_remote_data_source.dart';
import 'data/repositories/permissions_repository_impl.dart';
import 'domain/repositories/permissions_repository.dart';
import 'domain/use_cases/get_role_permissions_use_case.dart';
import 'domain/use_cases/update_role_permission_use_case.dart';
import 'presentation/cubit/permissions_cubit.dart';

void initPermissionsDI(GetIt sl) {
  // Data Sources
  if (!sl.isRegistered<PermissionsRemoteSource>()) {
    sl.registerLazySingleton<PermissionsRemoteSource>(
      () => PermissionsRemoteSourceImpl(sl()),
    );
  }

  // Repositories
  if (!sl.isRegistered<PermissionsRepository>()) {
    sl.registerLazySingleton<PermissionsRepository>(
      () => PermissionsRepositoryImpl(sl()),
    );
  }

  // Use Cases
  sl.registerLazySingleton(() => GetRolePermissionsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateRolePermissionUseCase(sl()));

  // Cubits
  sl.registerFactory<PermissionsCubit>(
    () => PermissionsCubit(
      getRolePermissionsUseCase: sl(),
      updateRolePermissionUseCase: sl(),
    ),
  );
}
