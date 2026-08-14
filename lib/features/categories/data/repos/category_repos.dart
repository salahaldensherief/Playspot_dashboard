import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/repository_helper.dart';
import '../entities/category_entity.dart';
import '../entities/city_entity.dart';
import '../entities/activity_type_entity.dart';
import '../data_source/remote/category_remote_data_source.dart';
import '../models/category_model.dart';
import '../models/city_model.dart';
import '../models/activity_type_model.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories();
  Future<Either<Failure, void>> addCategory(CategoryEntity category);
  Future<Either<Failure, void>> updateCategory(CategoryEntity category);
  Future<Either<Failure, void>> deleteCategory(String id);

  // Cities
  Future<Either<Failure, List<CityEntity>>> getCities();
  Future<Either<Failure, void>> addCity(CityEntity city);
  Future<Either<Failure, void>> updateCity(CityEntity city);
  Future<Either<Failure, void>> deleteCity(String id);

  // Activity Types
  Future<Either<Failure, List<ActivityTypeEntity>>> getActivityTypes();
  Future<Either<Failure, ActivityTypeEntity>> addActivityType(ActivityTypeEntity activityType);
}

class CategoryRepositoryImpl with RepositoryHelper implements CategoryRepository {
  final CategoryRemoteSource _remoteSource;

  CategoryRepositoryImpl(this._remoteSource);

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    return await callRepository(() => _remoteSource.getCategories());
  }

  @override
  Future<Either<Failure, void>> addCategory(CategoryEntity category) async {
    return await callRepository(() => _remoteSource.addCategory(CategoryModel(
          id: category.id,
          nameAr: category.nameAr,
          nameEn: category.nameEn,
          iconKey: category.iconKey,
        )));
  }

  @override
  Future<Either<Failure, void>> updateCategory(CategoryEntity category) async {
    return await callRepository(() => _remoteSource.updateCategory(CategoryModel(
          id: category.id,
          nameAr: category.nameAr,
          nameEn: category.nameEn,
          iconKey: category.iconKey,
        )));
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    return await callRepository(() => _remoteSource.deleteCategory(id));
  }

  @override
  Future<Either<Failure, List<CityEntity>>> getCities() async {
    return await callRepository(() => _remoteSource.getCities());
  }

  @override
  Future<Either<Failure, void>> addCity(CityEntity city) async {
    return await callRepository(() => _remoteSource.addCity(CityModel(
          id: city.id,
          nameAr: city.nameAr,
          nameEn: city.nameEn,
          isActive: city.isActive,
        )));
  }

  @override
  Future<Either<Failure, void>> updateCity(CityEntity city) async {
    return await callRepository(() => _remoteSource.updateCity(CityModel(
          id: city.id,
          nameAr: city.nameAr,
          nameEn: city.nameEn,
          isActive: city.isActive,
        )));
  }

  @override
  Future<Either<Failure, void>> deleteCity(String id) async {
    return await callRepository(() => _remoteSource.deleteCity(id));
  }

  @override
  Future<Either<Failure, List<ActivityTypeEntity>>> getActivityTypes() async {
    return await callRepository(() => _remoteSource.getActivityTypes());
  }

  @override
  Future<Either<Failure, ActivityTypeEntity>> addActivityType(ActivityTypeEntity activityType) async {
    return await callRepository(() => _remoteSource.addActivityType(ActivityTypeModel(
          id: activityType.id,
          name: activityType.name,
          label: activityType.label,
          sortOrder: activityType.sortOrder,
        )));
  }
}
