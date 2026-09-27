import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/category_repository.dart';

class DeleteCategoryUseCase implements UseCase<void, String> {
  final CategoryRepository repository;

  DeleteCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.deleteCategory(id);
  }
}
