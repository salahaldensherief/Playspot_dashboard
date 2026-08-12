import 'package:get_it/get_it.dart';
import 'data/datasources/lounge_remote_data_source.dart';
import 'data/repositories/lounge_repository_impl.dart';
import 'domain/repositories/lounge_repository.dart';
import 'presentation/cubit/lounge_cubit.dart';
import 'presentation/cubit/extras_cubit.dart';

void initLoungesDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<LoungeRemoteDataSource>(
    () => LoungeRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<LoungeRepository>(
    () => LoungeRepositoryImpl(sl()),
  );

  // Cubits
  sl.registerFactory<LoungeCubit>(
    () => LoungeCubit(sl()),
  );
  sl.registerFactory<ExtrasCubit>(
    () => ExtrasCubit(sl()),
  );
}
