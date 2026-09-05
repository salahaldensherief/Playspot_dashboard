import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/entities/category_entity.dart';
import '../../data/entities/city_entity.dart';
import '../../data/entities/activity_type_entity.dart';
import '../../data/repos/category_repos.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository _repository;

  CategoryCubit(this._repository) : super(CategoryState.init());

  Future<void> loadCategories({bool forceRefresh = false}) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final catResult = await _repository.getCategories(forceRefresh: forceRefresh);
    final cityResult = await _repository.getCities(forceRefresh: forceRefresh);
    final activityResult = await _repository.getActivityTypes(forceRefresh: forceRefresh);
    
    if (isClosed) return;

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
    final result = await _repository.addActivityType(newActivity);
    
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
    final result = await _repository.addCity(city);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: CategoryStatus.failure, errorMessage: failure.message)),
      (_) => loadCategories(),
    );
  }

  Future<void> updateCity(CityEntity city) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final result = await _repository.updateCity(city);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: CategoryStatus.failure, errorMessage: failure.message)),
      (_) => loadCategories(),
    );
  }

  Future<void> deleteCity(String id) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final result = await _repository.deleteCity(id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: CategoryStatus.failure, errorMessage: failure.message)),
      (_) => loadCategories(),
    );
  }

  Future<void> addCategory(CategoryEntity category) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final result = await _repository.addCategory(category);
    
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
    final result = await _repository.updateCategory(category);
    
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
    final result = await _repository.deleteCategory(id);
    
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
