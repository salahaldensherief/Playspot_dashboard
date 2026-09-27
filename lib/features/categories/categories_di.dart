import 'package:get_it/get_it.dart';
import 'data/data_source/remote/category_remote_data_source.dart';
import 'data/repositories/category_repository_impl.dart';
import 'domain/repositories/category_repository.dart';
import 'domain/usecases/add_category_usecase.dart';
import 'domain/usecases/delete_category_usecase.dart';
import 'domain/usecases/get_categories_usecase.dart';
import 'domain/usecases/manage_activity_types_usecases.dart';
import 'domain/usecases/manage_cities_usecases.dart';
import 'domain/usecases/update_category_usecase.dart';
import 'presentation/categories/category_cubit.dart';

void initCategoriesDI(GetIt sl) {
  // Data Sources
  if (!sl.isRegistered<CategoryRemoteSource>()) {
    sl.registerLazySingleton<CategoryRemoteSource>(
      () => CategoryRemoteSourceImpl(sl()),
    );
  }

  // Repositories
  if (!sl.isRegistered<CategoryRepository>()) {
    sl.registerLazySingleton<CategoryRepository>(
      () => CategoryRepositoryImpl(sl(), sl()),
    );
  }

  // Use Cases
  if (!sl.isRegistered<GetCategoriesUseCase>()) {
    sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  }
  if (!sl.isRegistered<AddCategoryUseCase>()) {
    sl.registerLazySingleton(() => AddCategoryUseCase(sl()));
  }
  if (!sl.isRegistered<UpdateCategoryUseCase>()) {
    sl.registerLazySingleton(() => UpdateCategoryUseCase(sl()));
  }
  if (!sl.isRegistered<DeleteCategoryUseCase>()) {
    sl.registerLazySingleton(() => DeleteCategoryUseCase(sl()));
  }

  if (!sl.isRegistered<GetCitiesUseCase>()) {
    sl.registerLazySingleton(() => GetCitiesUseCase(sl()));
  }
  if (!sl.isRegistered<AddCityUseCase>()) {
    sl.registerLazySingleton(() => AddCityUseCase(sl()));
  }
  if (!sl.isRegistered<UpdateCityUseCase>()) {
    sl.registerLazySingleton(() => UpdateCityUseCase(sl()));
  }
  if (!sl.isRegistered<DeleteCityUseCase>()) {
    sl.registerLazySingleton(() => DeleteCityUseCase(sl()));
  }

  if (!sl.isRegistered<GetActivityTypesUseCase>()) {
    sl.registerLazySingleton(() => GetActivityTypesUseCase(sl()));
  }
  if (!sl.isRegistered<AddActivityTypeUseCase>()) {
    sl.registerLazySingleton(() => AddActivityTypeUseCase(sl()));
  }

  // Cubits
  if (!sl.isRegistered<CategoryCubit>()) {
    sl.registerFactory<CategoryCubit>(
      () => CategoryCubit(
        getCategoriesUseCase: sl(),
        addCategoryUseCase: sl(),
        updateCategoryUseCase: sl(),
        deleteCategoryUseCase: sl(),
        getCitiesUseCase: sl(),
        addCityUseCase: sl(),
        updateCityUseCase: sl(),
        deleteCityUseCase: sl(),
        getActivityTypesUseCase: sl(),
        addActivityTypeUseCase: sl(),
      ),
    );
  }
}
