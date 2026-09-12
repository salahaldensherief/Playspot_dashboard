import 'package:get_it/get_it.dart';
import 'data/data_source/remote/staff_remote_data_source.dart';
import 'domain/repositories/staff_repository.dart';
import 'data/repositories/staff_repository_impl.dart';
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
