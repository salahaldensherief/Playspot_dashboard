import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class AddCategoryUseCase implements UseCase<void, CategoryEntity> {
  final CategoryRepository repository;

  AddCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CategoryEntity category) {
    return repository.addCategory(category);
  }
}
