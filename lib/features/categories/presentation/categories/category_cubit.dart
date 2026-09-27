import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/city_entity.dart';
import '../../domain/entities/activity_type_entity.dart';
import '../../domain/usecases/add_category_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/manage_activity_types_usecases.dart';
import '../../domain/usecases/manage_cities_usecases.dart';
import '../../domain/usecases/update_category_usecase.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final GetCategoriesUseCase _getCategoriesUseCase;
  final AddCategoryUseCase _addCategoryUseCase;
  final UpdateCategoryUseCase _updateCategoryUseCase;
  final DeleteCategoryUseCase _deleteCategoryUseCase;

  final GetCitiesUseCase _getCitiesUseCase;
  final AddCityUseCase _addCityUseCase;
  final UpdateCityUseCase _updateCityUseCase;
  final DeleteCityUseCase _deleteCityUseCase;

  final GetActivityTypesUseCase _getActivityTypesUseCase;
  final AddActivityTypeUseCase _addActivityTypeUseCase;

  CategoryCubit({
    required GetCategoriesUseCase getCategoriesUseCase,
    required AddCategoryUseCase addCategoryUseCase,
    required UpdateCategoryUseCase updateCategoryUseCase,
    required DeleteCategoryUseCase deleteCategoryUseCase,
    required GetCitiesUseCase getCitiesUseCase,
    required AddCityUseCase addCityUseCase,
    required UpdateCityUseCase updateCityUseCase,
    required DeleteCityUseCase deleteCityUseCase,
    required GetActivityTypesUseCase getActivityTypesUseCase,
    required AddActivityTypeUseCase addActivityTypeUseCase,
  })  : _getCategoriesUseCase = getCategoriesUseCase,
        _addCategoryUseCase = addCategoryUseCase,
        _updateCategoryUseCase = updateCategoryUseCase,
        _deleteCategoryUseCase = deleteCategoryUseCase,
        _getCitiesUseCase = getCitiesUseCase,
        _addCityUseCase = addCityUseCase,
        _updateCityUseCase = updateCityUseCase,
        _deleteCityUseCase = deleteCityUseCase,
        _getActivityTypesUseCase = getActivityTypesUseCase,
        _addActivityTypeUseCase = addActivityTypeUseCase,
        super(CategoryState.init());

  Future<void> loadCategories({bool forceRefresh = false}) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final results = await Future.wait([
      _getCategoriesUseCase(forceRefresh),
      _getCitiesUseCase(forceRefresh),
      _getActivityTypesUseCase(forceRefresh),
    ]);
    
    if (isClosed) return;

    final catResult = results[0] as Either<Failure, List<CategoryEntity>>;
    final cityResult = results[1] as Either<Failure, List<CityEntity>>;
    final activityResult = results[2] as Either<Failure, List<ActivityTypeEntity>>;

    catResult.fold(
      (failure) => emit(state.copyWith(
        status: CategoryStatus.failure,
        errorMessage: failure.message,
      )),
      (categories) {
        cityResult.fold(
          (failure) => emit(state.copyWith(
            status: CategoryStatus.failure,
            errorMessage: failure.message,
          )),
          (cities) {
            activityResult.fold(
              (failure) => emit(state.copyWith(
                status: CategoryStatus.failure,
                errorMessage: failure.message,
              )),
              (activities) => emit(state.copyWith(
                status: CategoryStatus.success,
                categories: categories,
                cities: cities,
                activityTypes: activities,
              )),
            );
          },
        );
      },
    );
  }

  // Activity Types Management
  Future<ActivityTypeEntity?> addActivityType(String name, String label) async {
    final newActivity = ActivityTypeEntity(id: '', name: name, label: label);
    final result = await _addActivityTypeUseCase(newActivity);
    
    return result.fold(
      (failure) {
        emit(state.copyWith(status: CategoryStatus.failure, errorMessage: failure.message));
        return null;
      },
      (activity) {
        loadCategories();
        return activity;
      },
    );
  }

  // Cities Management
  Future<void> addCity(CityEntity city) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final result = await _addCityUseCase(city);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: CategoryStatus.failure, errorMessage: failure.message)),
      (_) => loadCategories(),
    );
  }

  Future<void> updateCity(CityEntity city) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final result = await _updateCityUseCase(city);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: CategoryStatus.failure, errorMessage: failure.message)),
      (_) => loadCategories(),
    );
  }

  Future<void> deleteCity(String id) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final result = await _deleteCityUseCase(id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: CategoryStatus.failure, errorMessage: failure.message)),
      (_) => loadCategories(),
    );
  }

  Future<void> addCategory(CategoryEntity category) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final result = await _addCategoryUseCase(category);
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: CategoryStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => loadCategories(),
    );
  }

  Future<void> updateCategory(CategoryEntity category) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final result = await _updateCategoryUseCase(category);
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: CategoryStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => loadCategories(),
    );
  }

  Future<void> deleteCategory(String id) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final result = await _deleteCategoryUseCase(id);
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: CategoryStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => loadCategories(),
    );
  }
}
