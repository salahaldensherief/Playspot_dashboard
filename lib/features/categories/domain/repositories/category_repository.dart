import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/category_entity.dart';
import '../entities/city_entity.dart';
import '../entities/activity_type_entity.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories({bool forceRefresh = false});
  Future<Either<Failure, void>> addCategory(CategoryEntity category);
  Future<Either<Failure, void>> updateCategory(CategoryEntity category);
  Future<Either<Failure, void>> deleteCategory(String id);

  // Cities
  Future<Either<Failure, List<CityEntity>>> getCities({bool forceRefresh = false});
  Future<Either<Failure, void>> addCity(CityEntity city);
  Future<Either<Failure, void>> updateCity(CityEntity city);
  Future<Either<Failure, void>> deleteCity(String id);

  // Activity Types
  Future<Either<Failure, List<ActivityTypeEntity>>> getActivityTypes({bool forceRefresh = false});
  Future<Either<Failure, ActivityTypeEntity>> addActivityType(ActivityTypeEntity activityType);
}
