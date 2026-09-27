import 'package:get_it/get_it.dart';
import 'data/data_source/remote/staff_remote_data_source.dart';
import 'data/repositories/staff_repository_impl.dart';
import 'domain/repositories/staff_repository.dart';
import 'domain/usecases/add_staff_member_usecase.dart';
import 'domain/usecases/delete_staff_usecase.dart';
import 'domain/usecases/get_lounge_staff_usecase.dart';
import 'domain/usecases/update_staff_member_usecase.dart';
import 'domain/usecases/update_staff_status_usecase.dart';
import 'presentation/staff_management/staff_cubit.dart';

void initStaffDI(GetIt sl) {
  // Data Sources
  if (!sl.isRegistered<StaffRemoteSource>()) {
    sl.registerLazySingleton<StaffRemoteSource>(
      () => StaffRemoteSourceImpl(sl()),
    );
  }

  // Repositories
  if (!sl.isRegistered<StaffRepository>()) {
    sl.registerLazySingleton<StaffRepository>(
      () => StaffRepositoryImpl(sl()),
    );
  }

  // Use Cases
  if (!sl.isRegistered<GetLoungeStaffUseCase>()) {
    sl.registerLazySingleton(() => GetLoungeStaffUseCase(sl()));
  }
  if (!sl.isRegistered<AddStaffMemberUseCase>()) {
    sl.registerLazySingleton(() => AddStaffMemberUseCase(sl()));
  }
  if (!sl.isRegistered<UpdateStaffMemberUseCase>()) {
    sl.registerLazySingleton(() => UpdateStaffMemberUseCase(sl()));
  }
  if (!sl.isRegistered<UpdateStaffStatusUseCase>()) {
    sl.registerLazySingleton(() => UpdateStaffStatusUseCase(sl()));
  }
  if (!sl.isRegistered<DeleteStaffUseCase>()) {
    sl.registerLazySingleton(() => DeleteStaffUseCase(sl()));
  }

  // Cubits
  if (!sl.isRegistered<StaffCubit>()) {
    sl.registerFactory<StaffCubit>(
      () => StaffCubit(
        getLoungeStaffUseCase: sl(),
        addStaffMemberUseCase: sl(),
        updateStaffMemberUseCase: sl(),
        updateStaffStatusUseCase: sl(),
        deleteStaffUseCase: sl(),
      ),
    );
  }
}
