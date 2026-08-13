import 'package:equatable/equatable.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/city_entity.dart';

enum CategoryStatus { initial, loading, success, failure }

class CategoryState extends Equatable {
  final CategoryStatus status;
  final List<CategoryEntity> categories;
  final List<CityEntity> cities;
  final String? errorMessage;

  const CategoryState({
    this.status = CategoryStatus.initial,
    this.categories = const [],
    this.cities = const [],
    this.errorMessage,
  });

  CategoryState copyWith({
    CategoryStatus? status,
    List<CategoryEntity>? categories,
    List<CityEntity>? cities,
    String? errorMessage,
  }) {
    return CategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      cities: cities ?? this.cities,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, categories, cities, errorMessage];
}
