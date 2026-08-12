import 'package:get_it/get_it.dart';
import 'data/datasources/category_remote_data_source.dart';
import 'data/repositories/category_repository_impl.dart';
import 'domain/repositories/category_repository.dart';
import 'presentation/cubit/category_cubit.dart';

void initCategoriesDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(sl()),
  );

  // Cubits
  sl.registerFactory<CategoryCubit>(
    () => CategoryCubit(sl()),
  );
}
