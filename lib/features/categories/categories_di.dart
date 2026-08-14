import 'package:get_it/get_it.dart';
import 'data/data_source/remote/category_remote_data_source.dart';
import 'data/repos/category_repos.dart';
import 'presentation/categories/category_cubit.dart';

void initCategoriesDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<CategoryRemoteSource>(
    () => CategoryRemoteSourceImpl(sl()),
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
