import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/city_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_data_source.dart';
import '../models/category_model.dart';
import '../models/city_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;

  CategoryRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    try {
      final categories = await remoteDataSource.getCategories();
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addCategory(CategoryEntity category) async {
    try {
      await remoteDataSource.addCategory(CategoryModel(
        id: category.id,
        nameAr: category.nameAr,
        nameEn: category.nameEn,
        iconKey: category.iconKey,
      ));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCategory(CategoryEntity category) async {
    try {
      await remoteDataSource.updateCategory(CategoryModel(
        id: category.id,
        nameAr: category.nameAr,
        nameEn: category.nameEn,
        iconKey: category.iconKey,
      ));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    try {
      await remoteDataSource.deleteCategory(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Cities Implementation
  @override
  Future<Either<Failure, List<CityEntity>>> getCities() async {
    try {
      final cities = await remoteDataSource.getCities();
      return Right(cities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addCity(CityEntity city) async {
    try {
      await remoteDataSource.addCity(CityModel(
        id: city.id,
        nameAr: city.nameAr,
        nameEn: city.nameEn,
        isActive: city.isActive,
      ));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCity(CityEntity city) async {
    try {
      await remoteDataSource.updateCity(CityModel(
        id: city.id,
        nameAr: city.nameAr,
        nameEn: city.nameEn,
        isActive: city.isActive,
      ));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCity(String id) async {
    try {
      await remoteDataSource.deleteCity(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
