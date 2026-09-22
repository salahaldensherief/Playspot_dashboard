import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class UpdateCategoryUseCase implements UseCase<void, CategoryEntity> {
  final CategoryRepository repository;

  UpdateCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CategoryEntity category) {
    return repository.updateCategory(category);
  }
}
