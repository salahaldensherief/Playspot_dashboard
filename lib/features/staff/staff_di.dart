import 'package:get_it/get_it.dart';
import 'data/data_source/remote/staff_remote_data_source.dart';
import 'data/repos/staff_repos.dart';
import 'presentation/staff_management/staff_cubit.dart';

void initStaffDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<StaffRemoteSource>(
    () => StaffRemoteSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<StaffRepository>(
    () => StaffRepositoryImpl(sl()),
  );

  // Cubits
  sl.registerFactory<StaffCubit>(
    () => StaffCubit(sl()),
  );
}
