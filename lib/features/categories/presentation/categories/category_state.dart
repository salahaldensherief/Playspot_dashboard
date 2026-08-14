import 'package:equatable/equatable.dart';
import '../../data/entities/category_entity.dart';
import '../../data/entities/city_entity.dart';
import '../../data/entities/activity_type_entity.dart';

enum CategoryStatus {
  initial,
  loading,
  success,
  failure;

  bool get isInitial => this == CategoryStatus.initial;
  bool get isLoading => this == CategoryStatus.loading;
  bool get isSuccess => this == CategoryStatus.success;
  bool get isFailure => this == CategoryStatus.failure;
}

class CategoryState extends Equatable {
  final CategoryStatus status;
  final List<CategoryEntity> categories;
  final List<CityEntity> cities;
  final List<ActivityTypeEntity> activityTypes;
  final String? errorMessage;

  const CategoryState({
    required this.status,
    required this.categories,
    required this.cities,
    required this.activityTypes,
    this.errorMessage,
  });

  factory CategoryState.init() {
    return const CategoryState(
      status: CategoryStatus.initial,
      categories: [],
      cities: [],
      activityTypes: [],
    );
  }

  CategoryState copyWith({
    CategoryStatus? status,
    List<CategoryEntity>? categories,
    List<CityEntity>? cities,
    List<ActivityTypeEntity>? activityTypes,
    String? errorMessage,
  }) {
    return CategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      cities: cities ?? this.cities,
      activityTypes: activityTypes ?? this.activityTypes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, categories, cities, activityTypes, errorMessage];
}
