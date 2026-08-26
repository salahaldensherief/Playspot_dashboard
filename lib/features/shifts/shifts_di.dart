import 'package:get_it/get_it.dart';
import 'data/data_sources/shift_remote_data_source.dart';
import 'data/repositories/shift_repository_impl.dart';
import 'domain/repositories/shift_repository.dart';
import 'domain/use_cases/get_current_shift_use_case.dart';
import 'domain/use_cases/open_shift_use_case.dart';
import 'domain/use_cases/close_shift_use_case.dart';
import 'presentation/shift_management/shift_cubit.dart';

void initShiftsDI(GetIt sl) {
  // Data Sources
  if (!sl.isRegistered<ShiftRemoteDataSource>()) {
    sl.registerLazySingleton<ShiftRemoteDataSource>(
      () => ShiftRemoteDataSourceImpl(sl()),
    );
  }

  // Repositories
  if (!sl.isRegistered<ShiftRepository>()) {
    sl.registerLazySingleton<ShiftRepository>(
      () => ShiftRepositoryImpl(sl()),
    );
  }

  // Use Cases
  sl.registerLazySingleton(() => GetCurrentShiftUseCase(sl()));
  sl.registerLazySingleton(() => OpenShiftUseCase(sl()));
  sl.registerLazySingleton(() => CloseShiftUseCase(sl()));

  // Cubits
  sl.registerFactory<ShiftCubit>(
    () => ShiftCubit(sl(), sl(), sl(), sl()),
  );
}
