import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/category_entity.dart';
import '../entities/city_entity.dart';

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
}
