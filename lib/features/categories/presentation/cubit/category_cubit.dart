import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository repository;

  CategoryCubit(this.repository) : super(const CategoryState());

  Future<void> loadCategories() async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final result = await repository.getCategories();
    result.fold(
      (failure) => emit(state.copyWith(
        status: CategoryStatus.failure,
        errorMessage: failure.message,
      )),
      (categories) => emit(state.copyWith(
        status: CategoryStatus.success,
        categories: categories,
      )),
    );
  }

  Future<void> addCategory(CategoryEntity category) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final result = await repository.addCategory(category);
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
    result.fold(
      (failure) => emit(state.copyWith(
        status: CategoryStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => loadCategories(),
    );
  }
}
