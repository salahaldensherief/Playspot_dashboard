import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/city_entity.dart';
import '../../domain/repositories/category_repository.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository repository;

  CategoryCubit(this.repository) : super(const CategoryState());

  Future<void> loadCategories() async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final catResult = await repository.getCategories();
    final cityResult = await repository.getCities();
    
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
          (cities) => emit(state.copyWith(
            status: CategoryStatus.success,
            categories: categories,
            cities: cities,
          )),
        );
      },
    );
  }

  // Cities Management
  Future<void> addCity(CityEntity city) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final result = await repository.addCity(city);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: CategoryStatus.failure, errorMessage: failure.message)),
      (_) => loadCategories(),
    );
  }

  Future<void> updateCity(CityEntity city) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final result = await repository.updateCity(city);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: CategoryStatus.failure, errorMessage: failure.message)),
      (_) => loadCategories(),
    );
  }

  Future<void> deleteCity(String id) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final result = await repository.deleteCity(id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: CategoryStatus.failure, errorMessage: failure.message)),
      (_) => loadCategories(),
    );
  }

  Future<void> addCategory(CategoryEntity category) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final result = await repository.addCategory(category);
    
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
    final result = await repository.updateCategory(category);
    
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
    final result = await repository.deleteCategory(id);
    
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
