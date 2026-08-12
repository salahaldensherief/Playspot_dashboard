import 'package:get_it/get_it.dart';
import 'data/datasources/room_remote_data_source.dart';
import 'data/repositories/room_repository_impl.dart';
import 'domain/repositories/room_repository.dart';
import 'presentation/cubit/room_cubit.dart';

void initRoomsDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<RoomRemoteDataSource>(
    () => RoomRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<RoomRepository>(
    () => RoomRepositoryImpl(sl()),
  );

  // Cubits
  sl.registerFactory<RoomCubit>(
    () => RoomCubit(sl()),
  );
}
