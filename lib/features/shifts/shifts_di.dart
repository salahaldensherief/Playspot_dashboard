import 'package:get_it/get_it.dart';
import 'data/data_sources/shift_remote_data_source.dart';
import 'data/repositories/shift_repository_impl.dart';
import 'domain/repositories/shift_repository.dart';
import 'domain/use_cases/get_active_shift_use_case.dart';
import 'domain/use_cases/get_lounge_live_shift_overview_use_case.dart';
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
  if (!sl.isRegistered<GetActiveShiftUseCase>()) {
    sl.registerLazySingleton(() => GetActiveShiftUseCase(sl()));
  }
  if (!sl.isRegistered<GetLoungeLiveShiftOverviewUseCase>()) {
    sl.registerLazySingleton(() => GetLoungeLiveShiftOverviewUseCase(sl()));
  }
  if (!sl.isRegistered<OpenShiftUseCase>()) {
    sl.registerLazySingleton(() => OpenShiftUseCase(sl()));
  }
  if (!sl.isRegistered<CloseShiftUseCase>()) {
    sl.registerLazySingleton(() => CloseShiftUseCase(sl()));
  }

  // Cubits
  if (!sl.isRegistered<ShiftCubit>()) {
    sl.registerFactory<ShiftCubit>(
      () => ShiftCubit(
        getActiveShiftUseCase: sl(),
        getLoungeLiveShiftOverviewUseCase: sl(),
        openShiftUseCase: sl(),
        closeShiftUseCase: sl(),
        repository: sl(),
      ),
    );
  }
}
