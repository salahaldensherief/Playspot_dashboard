import 'package:get_it/get_it.dart';
import 'data/data_source/remote/shift_remote_data_source.dart';
import 'data/repos/shift_repos.dart';
import 'presentation/shift_management/shift_cubit.dart';

void initShiftsDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<ShiftRemoteSource>(
    () => ShiftRemoteSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<ShiftRepository>(
    () => ShiftRepositoryImpl(sl()),
  );

  // Cubits
  sl.registerFactory<ShiftCubit>(
    () => ShiftCubit(sl()),
  );
}
