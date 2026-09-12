import 'package:get_it/get_it.dart';
import 'data/data_source/remote/category_remote_data_source.dart';
import 'domain/repositories/category_repository.dart';
import 'data/repositories/category_repository_impl.dart';
import 'presentation/categories/category_cubit.dart';

void initCategoriesDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<CategoryRemoteSource>(
    () => CategoryRemoteSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(sl(), sl()),
  );

  // Cubits
  sl.registerFactory<CategoryCubit>(
    () => CategoryCubit(sl()),
  );
}
