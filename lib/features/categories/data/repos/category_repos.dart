import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/utils/repository_helper.dart';
import '../entities/category_entity.dart';
import '../entities/city_entity.dart';
import '../entities/activity_type_entity.dart';
import '../data_source/remote/category_remote_data_source.dart';
import '../models/category_model.dart';
import '../models/city_model.dart';
import '../models/activity_type_model.dart';

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

class CategoryRepositoryImpl with RepositoryHelper implements CategoryRepository {
  final CategoryRemoteSource _remoteSource;
  final LocalCacheService _localCacheService;

  CategoryRepositoryImpl(this._remoteSource, this._localCacheService);

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories({bool forceRefresh = false}) async {
    const cacheKey = 'cache_categories';
    try {
      if (!forceRefresh) {
        final cached = _localCacheService.getJson(cacheKey);
        if (cached is List && cached.isNotEmpty) {
          final categories = cached
              .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .map((m) => m as CategoryEntity)
              .toList();
          _refreshCategoriesInBackground(cacheKey);
          return Right(categories);
        }
      }

      final result = await callRepository(() => _remoteSource.getCategories());
      result.fold(
        (_) => null,
        (categories) {
          final models = categories.map((c) => CategoryModel(
            id: c.id,
            nameAr: c.nameAr,
            nameEn: c.nameEn,
            iconKey: c.iconKey,
          )).toList();
          _localCacheService.setJson(cacheKey, models.map((m) => m.toJson()).toList());
        },
      );
      return result;
    } catch (e) {
      final cached = _localCacheService.getJson(cacheKey);
      if (cached is List && cached.isNotEmpty) {
        final categories = cached
            .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .map((m) => m as CategoryEntity)
            .toList();
        return Right(categories);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  void _refreshCategoriesInBackground(String cacheKey) async {
    try {
      final categories = await _remoteSource.getCategories();
      final models = categories.map((c) => CategoryModel(
        id: c.id,
        nameAr: c.nameAr,
        nameEn: c.nameEn,
        iconKey: c.iconKey,
      )).toList();
      await _localCacheService.setJson(cacheKey, models.map((m) => m.toJson()).toList());
    } catch (_) {}
  }

  @override
  Future<Either<Failure, void>> addCategory(CategoryEntity category) async {
    final result = await callRepository(() => _remoteSource.addCategory(CategoryModel(
          id: category.id,
          nameAr: category.nameAr,
          nameEn: category.nameEn,
          iconKey: category.iconKey,
        )));
    if (result.isRight()) {
      await _localCacheService.remove('cache_categories');
    }
    return result;
  }

  @override
  Future<Either<Failure, void>> updateCategory(CategoryEntity category) async {
    final result = await callRepository(() => _remoteSource.updateCategory(CategoryModel(
          id: category.id,
          nameAr: category.nameAr,
          nameEn: category.nameEn,
          iconKey: category.iconKey,
        )));
    if (result.isRight()) {
      await _localCacheService.remove('cache_categories');
    }
    return result;
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    final result = await callRepository(() => _remoteSource.deleteCategory(id));
    if (result.isRight()) {
      await _localCacheService.remove('cache_categories');
    }
    return result;
  }

  @override
  Future<Either<Failure, List<CityEntity>>> getCities({bool forceRefresh = false}) async {
    const cacheKey = 'cache_cities';
    try {
      if (!forceRefresh) {
        final cached = _localCacheService.getJson(cacheKey);
        if (cached is List && cached.isNotEmpty) {
          final cities = cached
              .map((item) => CityModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .map((m) => m as CityEntity)
              .toList();
          _refreshCitiesInBackground(cacheKey);
          return Right(cities);
        }
      }

      final result = await callRepository(() => _remoteSource.getCities());
      result.fold(
        (_) => null,
        (cities) {
          final models = cities.map((c) => CityModel(
            id: c.id,
            nameAr: c.nameAr,
            nameEn: c.nameEn,
            isActive: c.isActive,
          )).toList();
          _localCacheService.setJson(cacheKey, models.map((m) => m.toJson()).toList());
        },
      );
      return result;
    } catch (e) {
      final cached = _localCacheService.getJson(cacheKey);
      if (cached is List && cached.isNotEmpty) {
        final cities = cached
            .map((item) => CityModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .map((m) => m as CityEntity)
            .toList();
        return Right(cities);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  void _refreshCitiesInBackground(String cacheKey) async {
    try {
      final cities = await _remoteSource.getCities();
      final models = cities.map((c) => CityModel(
        id: c.id,
        nameAr: c.nameAr,
        nameEn: c.nameEn,
        isActive: c.isActive,
      )).toList();
      await _localCacheService.setJson(cacheKey, models.map((m) => m.toJson()).toList());
    } catch (_) {}
  }

  @override
  Future<Either<Failure, void>> addCity(CityEntity city) async {
    final result = await callRepository(() => _remoteSource.addCity(CityModel(
          id: city.id,
          nameAr: city.nameAr,
          nameEn: city.nameEn,
          isActive: city.isActive,
        )));
    if (result.isRight()) {
      await _localCacheService.remove('cache_cities');
    }
    return result;
  }

  @override
  Future<Either<Failure, void>> updateCity(CityEntity city) async {
    final result = await callRepository(() => _remoteSource.updateCity(CityModel(
          id: city.id,
          nameAr: city.nameAr,
          nameEn: city.nameEn,
          isActive: city.isActive,
        )));
    if (result.isRight()) {
      await _localCacheService.remove('cache_cities');
    }
    return result;
  }

  @override
  Future<Either<Failure, void>> deleteCity(String id) async {
    final result = await callRepository(() => _remoteSource.deleteCity(id));
    if (result.isRight()) {
      await _localCacheService.remove('cache_cities');
    }
    return result;
  }

  @override
  Future<Either<Failure, List<ActivityTypeEntity>>> getActivityTypes({bool forceRefresh = false}) async {
    const cacheKey = 'cache_activity_types';
    try {
      if (!forceRefresh) {
        final cached = _localCacheService.getJson(cacheKey);
        if (cached is List && cached.isNotEmpty) {
          final activities = cached
              .map((item) => ActivityTypeModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .map((m) => m as ActivityTypeEntity)
              .toList();
          _refreshActivityTypesInBackground(cacheKey);
          return Right(activities);
        }
      }

      final result = await callRepository(() => _remoteSource.getActivityTypes());
      result.fold(
        (_) => null,
        (activities) {
          final models = activities.map((a) => ActivityTypeModel(
            id: a.id,
            name: a.name,
            label: a.label,
            sortOrder: a.sortOrder,
          )).toList();
          _localCacheService.setJson(cacheKey, models.map((m) => m.toJson()).toList());
        },
      );
      return result;
    } catch (e) {
      final cached = _localCacheService.getJson(cacheKey);
      if (cached is List && cached.isNotEmpty) {
        final activities = cached
            .map((item) => ActivityTypeModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .map((m) => m as ActivityTypeEntity)
            .toList();
        return Right(activities);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  void _refreshActivityTypesInBackground(String cacheKey) async {
    try {
      final activities = await _remoteSource.getActivityTypes();
      final models = activities.map((a) => ActivityTypeModel(
        id: a.id,
        name: a.name,
        label: a.label,
        sortOrder: a.sortOrder,
      )).toList();
      await _localCacheService.setJson(cacheKey, models.map((m) => m.toJson()).toList());
    } catch (_) {}
  }

  @override
  Future<Either<Failure, ActivityTypeEntity>> addActivityType(ActivityTypeEntity activityType) async {
    final result = await callRepository(() => _remoteSource.addActivityType(ActivityTypeModel(
          id: activityType.id,
          name: activityType.name,
          label: activityType.label,
          sortOrder: activityType.sortOrder,
        )));
    if (result.isRight()) {
      await _localCacheService.remove('cache_activity_types');
    }
    return result;
  }
}
